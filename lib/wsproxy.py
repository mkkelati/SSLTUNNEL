#!/usr/bin/env python3
# ============================================
#  SSH TUNNEL MANAGER - WebSocket Proxy
#  For HTTP Injector, ePro, HTTP Custom
#  Chain: Client -> Stunnel(TLS) -> This Proxy -> SSH
#
#  HTTP Injector "Custom Payload" mode behavior:
#  - Client sends HTTP upgrade request
#  - Proxy responds with 101 Switching Protocols
#  - After 101, client sends RAW data (no WS framing)
#  - Proxy relays raw data bidirectionally to SSH
#
#  Key: Connect SSH FIRST, then send 101, then raw relay
# ============================================

import socket
import threading
import sys
import select
import time
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

    def run(self):
        try:
            # Step 1: Read client HTTP request
            data = self.client.recv(BUFLEN)
            if not data:
                return

            # Step 2: Set TCP_NODELAY on client socket
            self.client.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

            # Step 3: Connect to SSH FIRST (SSH is ready before client gets response)
            self.target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.target.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.target.connect((DEFAULT_HOST, DEFAULT_PORT))

            # Step 4: Parse headers and send appropriate response
            headers = parse_http_headers(data)
            upgrade = headers.get('upgrade', '').lower()
            ws_key = headers.get('sec-websocket-key', '')

            if upgrade == 'websocket' or 'upgrade' in headers.get('connection', '').lower():
                # WebSocket upgrade request - respond with 101
                accept_key = compute_accept_key(ws_key) if ws_key else None
                response = 'HTTP/1.1 101 Switching Protocols\r\n'
                response += 'Upgrade: websocket\r\n'
                response += 'Connection: Upgrade\r\n'
                if accept_key:
                    response += 'Sec-WebSocket-Accept: ' + accept_key + '\r\n'
                response += '\r\n'
                self.client.sendall(response.encode())
            else:
                # CONNECT or other request - respond with 200
                self.client.sendall(b'HTTP/1.1 200 Connection established\r\n\r\n')

            # Step 5: Raw bidirectional relay
            # HTTP Injector "Custom Payload" mode does NOT apply WebSocket
            # framing after 101 - it sends raw SSH data directly
            self._relay()

        except Exception:
            pass
        finally:
            self._close()

    def _relay(self):
        """Bidirectional raw TCP relay between client and SSH."""
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
    print(':  Mode: 101 + Raw Relay (HTTP Injector)   :')
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
