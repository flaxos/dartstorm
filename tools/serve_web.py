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


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_PORT
    if not os.path.exists(os.path.join(WEB_DIR, "index.html")):
        print(f"ERROR: Web build not found at {WEB_DIR}/index.html.")
        print("Run './tools/export_web.sh' first to build the web export.")
        sys.exit(1)

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", port), DartstormHTTPRequestHandler) as httpd:
        print(f"============================================================")
        print(f"  DARTSTORM Web Server running at: http://localhost:{port}/")
        print(f"  Serving files from: {WEB_DIR}")
        print(f"  Press Ctrl+C to stop.")
        print(f"============================================================")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")


if __name__ == "__main__":
    main()
