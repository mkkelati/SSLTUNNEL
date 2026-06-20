#!/usr/bin/env python3
# ============================================
#  SSH TUNNEL MANAGER - WebSocket Proxy
# ============================================

import socket
import threading
import sys
import select
import hashlib
import base64
import struct

BUFLEN = 4096
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1:22'
WS_MAGIC = '258EAFA5-E914-47DA-95CA-5AB9DC525C63'

class WebSocketProxy(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.lock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(5)
        self.running = True

        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue
                conn = WSHandler(c, self, addr)
                conn.start()
                with self.lock:
                    self.threads.append(conn)
        finally:
            self.running = False
            self.soc.close()

    def close(self):
        self.running = False
        with self.lock:
            for t in self.threads:
                t.running = False


class WSHandler(threading.Thread):
    def __init__(self, client, server, addr):
        threading.Thread.__init__(self)
        self.client = client
        self.server = server
        self.addr = addr
        self.running = True

    def close(self):
        try:
            self.client.shutdown(socket.SHUT_RDWR)
            self.client.close()
        except:
            pass
        try:
            self.target.shutdown(socket.SHUT_RDWR)
            self.target.close()
        except:
            pass

    def run(self):
        try:
            data = self.client.recv(BUFLEN).decode('utf-8', errors='ignore')
            
            if 'Upgrade: websocket' in data or 'upgrade: websocket' in data:
                self.handle_websocket(data)
            elif data.startswith('CONNECT'):
                self.handle_connect(data)
            elif data.startswith('GET') or data.startswith('POST'):
                # HTTP request without upgrade - respond 200 and relay to SSH
                response = 'HTTP/1.1 200 Connection Established\r\n\r\n'
                self.client.sendall(response.encode())
                self.connect_and_relay(DEFAULT_HOST)
            else:
                host_port = DEFAULT_HOST
                self.connect_and_relay(host_port)
        except Exception as e:
            pass
        finally:
            self.close()

    def handle_websocket(self, data):
        # Extract target host first
        host_port = DEFAULT_HOST
        for line in data.split('\r\n'):
            if line.startswith('X-Real-Host:'):
                host_port = line.split(':', 1)[1].strip()
                break
            elif line.startswith('Host:'):
                hp = line.split(':', 1)[1].strip()
                if ':' in hp:
                    host_port = hp

        # Extract WebSocket key
        key = ''
        for line in data.split('\r\n'):
            if line.lower().startswith('sec-websocket-key:'):
                key = line.split(':', 1)[1].strip()
                break

        if key:
            # Real WebSocket client with key - do proper WS handshake
            accept = base64.b64encode(
                hashlib.sha1((key + WS_MAGIC).encode()).digest()
            ).decode()

            response = (
                'HTTP/1.1 101 Switching Protocols\r\n'
                'Upgrade: websocket\r\n'
                'Connection: Upgrade\r\n'
                f'Sec-WebSocket-Accept: {accept}\r\n'
                '\r\n'
            )
            self.client.sendall(response.encode())
        else:
            # HTTP Injector / ePro custom payload (no WS key)
            # Connect to SSH FIRST so it's ready before client starts
            if ':' in host_port:
                host, port = host_port.rsplit(':', 1)
                port = int(port)
            else:
                host = host_port
                port = 22
            self.target = socket.socket(socket.AF_INET)
            self.target.connect((host, port))

            # Send 200 (raw tunnel) - NOT 101 which triggers WS framing
            response = 'HTTP/1.1 200 Connection Established\r\n\r\n'
            self.client.sendall(response.encode())

            # Go straight to relay (target already connected)
            self._relay()
            return

        self.connect_and_relay(host_port)

    def handle_connect(self, data):
        # Extract host:port from CONNECT line
        try:
            line = data.split('\r\n')[0]
            host_port = line.split(' ')[1]
        except:
            host_port = DEFAULT_HOST

        response = 'HTTP/1.1 200 Connection Established\r\n\r\n'
        self.client.sendall(response.encode())
        self.connect_and_relay(host_port)

    def connect_and_relay(self, host_port):
        if ':' in host_port:
            host, port = host_port.rsplit(':', 1)
            port = int(port)
        else:
            host = host_port
            port = 22

        self.target = socket.socket(socket.AF_INET)
        self.target.connect((host, port))
        self._relay()

    def _relay(self):
        socs = [self.client, self.target]
        count = 0
        while self.running:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                break
            if recv:
                for s in recv:
                    try:
                        data = s.recv(BUFLEN)
                        if not data:
                            self.running = False
                            break
                        if s is self.client:
                            self.target.sendall(data)
                        else:
                            self.client.sendall(data)
                        count = 0
                    except:
                        self.running = False
                        break
            if count >= TIMEOUT:
                break


def main(host, port):
    print("\n:---------------------------------------:")
    print(":  SSH Tunnel Manager - WebSocket Proxy :")
    print(":  Port: " + str(port) + "                              :")
    print(":---------------------------------------:\n")
    
    server = WebSocketProxy(host, port)
    server.start()
    
    try:
        while True:
            pass
    except KeyboardInterrupt:
        print('\nStopping...')
        server.close()

if __name__ == '__main__':
    port = 8799
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    main('', port)
