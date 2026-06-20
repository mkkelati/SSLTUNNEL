#!/usr/bin/env python3
# ============================================
#  SSH TUNNEL MANAGER - WebSocket/HTTP Proxy
#  For HTTP Injector, ePro, HTTP Custom
#  Chain: Client → Stunnel(TLS) → This Proxy → SSH
# ============================================

import socket
import threading
import sys
import select
import time

BUFLEN = 8192
TIMEOUT = 60
DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORT = 22
RESPONSE = b'HTTP/1.1 200 Connection established\r\n\r\n'


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
            # Step 1: Read client's HTTP payload/request
            data = self.client.recv(BUFLEN)
            if not data:
                return

            # Step 2: Set TCP_NODELAY to prevent Nagle buffering
            # This ensures our 200 response goes out as its own TCP segment
            self.client.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

            # Step 3: Send 200 response IMMEDIATELY
            # This tells HTTP Injector the tunnel is ready
            self.client.sendall(RESPONSE)

            # Step 4: NOW connect to SSH (after response is sent)
            # This prevents SSH banner from mixing with our HTTP response
            self.target = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.target.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            self.target.connect((DEFAULT_HOST, DEFAULT_PORT))

            # Step 5: Relay data bidirectionally
            self._relay()

        except Exception:
            pass
        finally:
            self._close()

    def _relay(self):
        """Bidirectional data relay between client and SSH target."""
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
    print(f"\n:------------------------------------------:")
    print(f":  SSH Tunnel Manager - HTTP/WS Proxy      :")
    print(f":  Listening on port: {port}                    :")
    print(f":  Forwarding to: {DEFAULT_HOST}:{DEFAULT_PORT}         :")
    print(f":------------------------------------------:\n")

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
