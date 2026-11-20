#!/usr/bin/env python3
"""Local development server for testing DARTSTORM Web builds.

Supports:
- Multi-threaded concurrent asset downloading (ThreadingHTTPServer)
- Dual HTTP (port 8910) and HTTPS (port 8911) serving
- Automatic local network IP discovery (LAN, WiFi)
- Cross-origin isolation headers (COOP/COEP) and correct WASM MIME types
- Automatic self-signed SSL certificate generation for HTTPS testing

Usage:
    python3 tools/serve_web.py [http_port]
    python3 tools/serve_web.py --http-only [http_port]
    python3 tools/serve_web.py --https-only [https_port]
"""

import argparse
import http.server
import os
import re
import socket
import ssl
import subprocess
import sys
import threading

DEFAULT_HTTP_PORT = 8910
DEFAULT_HTTPS_PORT = 8911
WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))
SSL_DIR = os.path.join(WEB_DIR, ".ssl")


class DartstormHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom request handler setting required WASM and isolation headers."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Cross-origin isolation and resource sharing headers
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache, must-revalidate")
        self.send_header("Accept-Ranges", "bytes")
        super().end_headers()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        if path.endswith(".js"):
            return "application/javascript"
        if path.endswith(".json"):
            return "application/json"
        return super().guess_type(path)

    def copyfile(self, source, outputfile):
        """Silently handle broken pipe errors from mobile disconnects/aborts."""
        try:
            super().copyfile(source, outputfile)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def log_message(self, format, *args):
        # Filter out noisy TLS handshake attempts on plain HTTP port
        if len(args) >= 1 and isinstance(args[0], str) and "\\x16\\x03\\x01" in args[0]:
            sys.stderr.write(
                "[Notice] An HTTPS request was sent to the HTTP port. "
                f"Please use the HTTPS port ({DEFAULT_HTTPS_PORT}) instead.\n"
            )
            return
        super().log_message(format, *args)


def get_local_ips():
    """Detect LAN and WiFi IP addresses on this host."""
    ips = []
    # 1. Primary route via UDP socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        primary = s.getsockname()[0]
        s.close()
        if primary and not primary.startswith("127."):
            ips.append(primary)
    except Exception:
        pass

    # 2. Network interfaces from 'ip -4 addr'
    try:
        out = subprocess.check_output(["ip", "-4", "addr", "show"], text=True)
        for match in re.finditer(r"inet\s+(\d+\.\d+\.\d+\.\d+)/\d+.*scope global", out):
            ip = match.group(1)
            # Prioritize standard home/office subnets (192.168.x.x, 10.x.x.x)
            if not ip.startswith("127.") and ip not in ips:
                if ip.startswith("192.168.") or ip.startswith("10."):
                    ips.insert(1 if len(ips) > 0 else 0, ip)
                else:
                    ips.append(ip)
    except Exception:
        pass

    return ips


def ensure_ssl_cert():
    """Generate self-signed SSL cert if openssl is available and cert doesn't exist."""
    os.makedirs(SSL_DIR, exist_ok=True)
    cert_file = os.path.join(SSL_DIR, "cert.pem")
    key_file = os.path.join(SSL_DIR, "key.pem")

    if os.path.exists(cert_file) and os.path.exists(key_file):
        return cert_file, key_file

    try:
        subprocess.check_call(
            [
                "openssl",
                "req",
                "-x509",
                "-newkey",
                "rsa:2048",
                "-keyout",
                key_file,
                "-out",
                cert_file,
                "-days",
                "365",
                "-nodes",
                "-subj",
                "/CN=dartstorm.local",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return cert_file, key_file
    except Exception as e:
        print(f"[Warning] Unable to generate SSL certificate: {e}")
        return None, None


def run_server(server, label):
    try:
        server.serve_forever()
    except Exception:
        pass


def main():
    parser = argparse.ArgumentParser(description="DARTSTORM Universal Web Server")
    parser.add_argument("port", nargs="?", type=int, default=DEFAULT_HTTP_PORT, help="HTTP port (default 8910)")
    parser.add_argument("--https-port", type=int, default=DEFAULT_HTTPS_PORT, help="HTTPS port (default 8911)")
    parser.add_argument("--http-only", action="store_true", help="Serve only HTTP")
    parser.add_argument("--https-only", action="store_true", help="Serve only HTTPS")
    args = parser.parse_args()

    http_port = args.port
    https_port = args.https_port if args.https_port != DEFAULT_HTTPS_PORT or http_port == DEFAULT_HTTP_PORT else http_port + 1

    if not os.path.exists(os.path.join(WEB_DIR, "index.html")):
        print(f"ERROR: Web build not found at {WEB_DIR}/index.html.")
        print("Run './tools/export_web.sh' first to build the web export.")
        sys.exit(1)

    servers = []
    threads = []
    local_ips = get_local_ips()

    # 1. Setup HTTP server
    httpd = None
    if not args.https_only:
        try:
            http.server.ThreadingHTTPServer.allow_reuse_address = True
            httpd = http.server.ThreadingHTTPServer(("", http_port), DartstormHTTPRequestHandler)
            servers.append(httpd)
        except OSError as e:
            print(f"ERROR starting HTTP server on port {http_port}: {e}")
            sys.exit(1)

    # 2. Setup HTTPS server
    httpsd = None
    if not args.http_only:
        cert_file, key_file = ensure_ssl_cert()
        if cert_file and key_file:
            try:
                ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
                ssl_ctx.load_cert_chain(certfile=cert_file, keyfile=key_file)
                http.server.ThreadingHTTPServer.allow_reuse_address = True
                httpsd = http.server.ThreadingHTTPServer(("", https_port), DartstormHTTPRequestHandler)
                httpsd.socket = ssl_ctx.wrap_socket(httpsd.socket, server_side=True)
                servers.append(httpsd)
            except OSError as e:
                print(f"[Warning] Could not start HTTPS server on port {https_port}: {e}")
                httpsd = None
        else:
            print("[Warning] OpenSSL not available, HTTPS disabled.")

    print("=" * 64)
    print("  DARTSTORM Universal Web Server is LIVE!")
    print("=" * 64)
    if httpd:
        print(f"  [HTTP] Direct LAN Access (Recommended - Instant, no SSL prompts):")
        print(f"    Local:   http://localhost:{http_port}/")
        for ip in local_ips:
            if ip.startswith("192.168.") or ip.startswith("10."):
                print(f"    Network: http://{ip}:{http_port}/")
    if httpsd:
        print()
        print(f"  [HTTPS] Secure Context Access (Accept self-signed cert on phone):")
        print(f"    Local:   https://localhost:{https_port}/")
        for ip in local_ips:
            if ip.startswith("192.168.") or ip.startswith("10."):
                print(f"    Network: https://{ip}:{https_port}/")
    print("-" * 64)
    print(f"  Serving Directory: {WEB_DIR}")
    print(f"  Multi-threaded Streaming: ENABLED")
    print("  Press Ctrl+C to stop.")
    print("=" * 64)
    sys.stdout.flush()

    for s in servers:
        t = threading.Thread(target=run_server, args=(s, ""), daemon=True)
        t.start()
        threads.append(t)

    try:
        for t in threads:
            t.join()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        for s in servers:
            s.shutdown()
        print("Server stopped cleanly.")


if __name__ == "__main__":
    main()

