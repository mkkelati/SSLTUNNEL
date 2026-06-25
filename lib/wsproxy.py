#!/usr/bin/env python3
# ============================================
#  SSH TUNNEL MANAGER - WebSocket Proxy
#  For HTTP Injector, ePro, HTTP Custom
#  Chain: Client -> Stunnel(TLS) -> This Proxy -> SSH
#
#  Proper WebSocket frame handling:
#  - Client sends WS upgrade -> 101 response
#  - Client->Proxy: WebSocket framed data (masked)
#  - Proxy->Client: WebSocket framed data (unmasked)
#  - Proxy<->SSH: Raw TCP
# ============================================

import socket
import threading
import sys
import select
import time
import struct
import hashlib
import base64

BUFLEN = 65536
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORT = 22
WS_MAGIC = b'258EAFA5-E914-47DA-95CA-5AB4EF6A63B9'


def compute_accept_key(key):
    """Compute Sec-WebSocket-Accept from client key."""
    if not key:
        return None
    sha1 = hashlib.sha1(key.strip().encode() + WS_MAGIC).digest()
    return base64.b64encode(sha1).decode()


def parse_http_headers(data):
    """Parse HTTP request headers into a dict."""
    headers = {}
    try:
        text = data.decode('utf-8', errors='ignore')
        lines = text.split('\r\n')
        for line in lines[1:]:
            if ':' in line:
                k, v = line.split(':', 1)
                headers[k.strip().lower()] = v.strip()
    except Exception:
        pass
    return headers


def decode_ws_frame(data):
    """
    Decode a WebSocket frame. Returns (payload, remaining_data, is_complete).
    Client->Server frames are always masked.
    """
    if len(data) < 2:
        return None, data, False

    b1 = data[0]
    b2 = data[1]
    opcode = b1 & 0x0F
    masked = (b2 & 0x80) != 0
    payload_len = b2 & 0x7F

    offset = 2
    if payload_len == 126:
        if len(data) < 4:
            return None, data, False
        payload_len = struct.unpack('>H', data[2:4])[0]
        offset = 4
    elif payload_len == 127:
        if len(data) < 10:
            return None, data, False
        payload_len = struct.unpack('>Q', data[2:10])[0]
        offset = 10

    if masked:
        if len(data) < offset + 4:
            return None, data, False
        mask_key = data[offset:offset + 4]
        offset += 4

    if len(data) < offset + payload_len:
        return None, data, False

    payload = data[offset:offset + payload_len]

    if masked:
        # Unmask the payload
        payload = bytearray(payload)
        for i in range(len(payload)):
            payload[i] ^= mask_key[i % 4]
        payload = bytes(payload)

    remaining = data[offset + payload_len:]

    # opcode 0x08 = close frame
    if opcode == 0x08:
        return None, remaining, True

    return payload, remaining, True


def encode_ws_frame(data):
    """
    Encode data into a WebSocket binary frame (server->client, unmasked).
    """
    frame = bytearray()
    # FIN=1, opcode=0x02 (binary)
    frame.append(0x82)

    length = len(data)
    if length < 126:
        frame.append(length)
    elif length < 65536:
        frame.append(126)
        frame.extend(struct.pack('>H', length))
    else:
        frame.append(127)
        frame.extend(struct.pack('>Q', length))

    frame.extend(data)
    return bytes(frame)


class ProxyServer(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.daemon = True
        self.running = False
        self.host = host
        self.port = port

    def run(self):
        self.soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(128)
        self.running = True

        try:
            while self.running:
                try:
                    client, addr = self.soc.accept()
                    client.setblocking(1)
                    handler = ConnectionHandler(client, addr)
                    handler.start()
                except socket.timeout:
                    continue
        finally:
            self.running = False
            self.soc.close()

    def close(self):
        self.running = False


class ConnectionHandler(threading.Thread):
    def __init__(self, client, addr):
        threading.Thread.__init__(self)
        self.daemon = True
        self.client = client
        self.addr = addr
        self.target = None
        self.running = True
        self.ws_mode = False

    def run(self):
        try:
            # Step 1: Read client HTTP request (WebSocket upgrade or CONNECT)
            data = self.client.recv(BUFLEN)
            if not data:
                return

            self.client.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

            # Step 2: Parse headers to determine mode
            headers = parse_http_headers(data)
            upgrade = headers.get('upgrade', '').lower()
            ws_key = headers.get('sec-websocket-key', '')

            # Step 3: Connect to SSH FIRST (ensures SSH is ready)
            self.target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.target.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.target.connect((DEFAULT_HOST, DEFAULT_PORT))

            # Step 4: Send appropriate response
            if upgrade == 'websocket' or 'upgrade' in headers.get('connection', '').lower():
                # WebSocket mode - send 101 with proper handshake
                self.ws_mode = True
                accept_key = compute_accept_key(ws_key) if ws_key else None

                response = 'HTTP/1.1 101 Switching Protocols\r\n'
                response += 'Upgrade: websocket\r\n'
                response += 'Connection: Upgrade\r\n'
                if accept_key:
                    response += 'Sec-WebSocket-Accept: ' + accept_key + '\r\n'
                response += '\r\n'
                self.client.sendall(response.encode())
            else:
                # CONNECT/raw mode - send 200
                self.ws_mode = False
                self.client.sendall(b'HTTP/1.1 200 Connection established\r\n\r\n')

            # Step 5: Relay with WebSocket frame handling
            if self.ws_mode:
                self._relay_websocket()
            else:
                self._relay_raw()

        except Exception:
            pass
        finally:
            self._close()

    def _relay_websocket(self):
        """
        Bidirectional relay with WebSocket frame handling.
        Client -> Proxy: WebSocket frames (decode, unmask, send raw to SSH)
        SSH -> Proxy -> Client: Raw data (encode as WebSocket frames)
        """
        sockets = [self.client, self.target]
        ws_buffer = b''
        idle_count = 0

        while self.running:
            try:
                readable, _, errors = select.select(sockets, [], sockets, 3)
            except Exception:
                break

            if errors:
                break

            if readable:
                idle_count = 0
                for sock in readable:
                    try:
                        raw = sock.recv(BUFLEN)
                        if not raw:
                            self.running = False
                            break

                        if sock is self.client:
                            # Client -> decode WebSocket frames -> send raw to SSH
                            ws_buffer += raw
                            while ws_buffer:
                                payload, ws_buffer, complete = decode_ws_frame(ws_buffer)
                                if not complete:
                                    break
                                if payload is None:
                                    # Close frame or incomplete
                                    if complete:
                                        self.running = False
                                    break
                                self.target.sendall(payload)
                        else:
                            # SSH -> encode as WebSocket frame -> send to client
                            frame = encode_ws_frame(raw)
                            self.client.sendall(frame)
                    except Exception:
                        self.running = False
                        break
            else:
                idle_count += 1
                if idle_count >= TIMEOUT:
                    break

    def _relay_raw(self):
        """Bidirectional raw TCP relay (for CONNECT mode)."""
        sockets = [self.client, self.target]
        idle_count = 0

        while self.running:
            try:
                readable, _, errors = select.select(sockets, [], sockets, 3)
            except Exception:
                break

            if errors:
                break

            if readable:
                idle_count = 0
                for sock in readable:
                    try:
                        data = sock.recv(BUFLEN)
                        if not data:
                            self.running = False
                            break
                        if sock is self.client:
                            self.target.sendall(data)
                        else:
                            self.client.sendall(data)
                    except Exception:
                        self.running = False
                        break
            else:
                idle_count += 1
                if idle_count >= TIMEOUT:
                    break

    def _close(self):
        for sock in (self.client, self.target):
            if sock:
                try:
                    sock.shutdown(socket.SHUT_RDWR)
                except Exception:
                    pass
                try:
                    sock.close()
                except Exception:
                    pass


def main(host, port):
    print('\n:------------------------------------------:')
    print(':  SSH Tunnel Manager - WebSocket Proxy    :')
    print(':  Listening on port: {:<22}:'.format(port))
    print(':  Forwarding to: {}:{:<17}:'.format(DEFAULT_HOST, DEFAULT_PORT))
    print(':  WebSocket frame support: ENABLED        :')
    print(':------------------------------------------:\n')

    server = ProxyServer(host, port)
    server.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print('\nStopping...')
        server.close()


if __name__ == '__main__':
    port = 8799
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    main('', port)
