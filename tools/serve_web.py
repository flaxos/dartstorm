#!/usr/bin/env python3
"""Local development HTTP server for testing DARTSTORM Web build.

Usage:
    python3 tools/serve_web.py [port]
"""

import http.server
import os
import socketserver
import sys

DEFAULT_PORT = 8000
WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))


class DartstormHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Allow cross-origin resources if needed
        self.send_header("Access-Control-Allow-Origin", "*")
        # COOP/COEP headers (safe for both threaded and non-threaded builds)
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        if path.endswith(".js"):
            return "application/javascript"
        return super().guess_type(path)


def get_local_ips():
    ips = []
    try:
        import subprocess
        output = subprocess.check_output(["hostname", "-I"], text=True)
        for ip in output.split():
            if ip and not ip.startswith("172.") and not ip.startswith("127.") and not ":" in ip:
                ips.append(ip)
    except Exception:
        pass
    return ips


def main():
    target_port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    if not os.path.exists(os.path.join(WEB_DIR, "index.html")):
        print(f"ERROR: Web build not found at {WEB_DIR}/index.html.")
        print("Run './tools/export_web.sh' first to build the web export.")
        sys.exit(1)

    socketserver.TCPServer.allow_reuse_address = True
    httpd = None
    port = target_port
    for candidate in [target_port, 8910, 8090, 8085, 9000]:
        try:
            httpd = socketserver.TCPServer(("", candidate), DartstormHTTPRequestHandler)
            port = candidate
            break
        except OSError:
            if len(sys.argv) > 1:
                print(f"ERROR: Requested port {candidate} is already in use.")
                sys.exit(1)
            continue

    if httpd is None:
        print("ERROR: Could not find an open port to bind HTTP server.")
        sys.exit(1)

    ips = get_local_ips()
    with httpd:
        print("============================================================")
        print("  DARTSTORM Web Server is LIVE!")
        print(f"  Local access:   http://localhost:{port}/")
        for ip in ips:
            print(f"  Network access: http://{ip}:{port}/")
        print(f"  Serving files from: {WEB_DIR}")
        print("  Press Ctrl+C to stop.")
        print("============================================================")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")


if __name__ == "__main__":
    main()

