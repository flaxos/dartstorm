#!/usr/bin/env python3
"""Local APK Download Server for DARTSTORM.

Binds natively to host port 8085 (0.0.0.0:8085) so mobile devices on the local
network or overlay VPN can download DARTSTORM.apk reliably with Range resume.

Features:
- Native Range header support (HTTP 206 Partial Content) for resilient mobile downloads
- Proper Android APK MIME type and Content-Disposition headers
- Route aliases: /, /apk, /download, /DARTSTORM.apk
- Strict path confinement inside build/download (prevents directory traversal)
- Multi-threaded request handling

Usage:
    python3 tools/serve_download.py [port]
"""

import argparse
import http.server
import os
import re
import socket
import socketserver
import sys
import urllib.parse

DEFAULT_PORT = 8085
DOWNLOAD_DIR = os.path.realpath(
    os.path.join(os.path.dirname(__file__), "..", "build", "download")
)
APK_PATH = os.path.join(DOWNLOAD_DIR, "DARTSTORM.apk")
HTML_PATH = os.path.join(DOWNLOAD_DIR, "index.html")


def _safe_download_path(rel_path: str):
    """Resolve rel_path strictly inside DOWNLOAD_DIR; return None on traversal or dotfiles."""
    decoded = urllib.parse.unquote(rel_path).lstrip("/")
    if not decoded:
        return None
    parts = [p for p in decoded.replace("\\", "/").split("/") if p]
    if any(p in (".", "..") or p.startswith(".") for p in parts):
        return None
    candidate = os.path.realpath(os.path.join(DOWNLOAD_DIR, *parts))
    try:
        if os.path.commonpath([DOWNLOAD_DIR, candidate]) != DOWNLOAD_DIR:
            return None
    except ValueError:
        return None
    return candidate if os.path.isfile(candidate) else None


def _detect_local_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        if ip and not ip.startswith("127."):
            return ip
    except Exception:
        pass
    return "127.0.0.1"


class DownloadHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_HEAD(self):
        self._handle_request(send_body=False)

    def do_GET(self):
        self._handle_request(send_body=True)

    def _handle_request(self, send_body=True):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")

        # Route aliases
        if path in ("", "/", "/apk", "/download", "/index.html"):
            if os.path.isfile(HTML_PATH):
                self._serve_file(HTML_PATH, "text/html; charset=utf-8", send_body)
            else:
                self._serve_fallback_index(send_body)
        elif path in ("/DARTSTORM.apk", "/download/DARTSTORM.apk", "/apk/DARTSTORM.apk"):
            self._serve_apk(send_body)
        else:
            file_path = _safe_download_path(parsed.path)
            if file_path is not None:
                self._serve_file(file_path, "application/octet-stream", send_body)
            else:
                self.send_error(404, "File Not Found")

    def _serve_fallback_index(self, send_body=True):
        apk_ready = os.path.isfile(APK_PATH)
        status = (
            '<p><a href="/DARTSTORM.apk">Download DARTSTORM.apk</a></p>'
            if apk_ready
            else "<p>DARTSTORM.apk has not been built yet. Run <code>./tools/export_apk.sh</code> first.</p>"
        )
        body = f"<!doctype html><html><head><meta charset='utf-8'><title>DARTSTORM Download</title></head><body><h1>DARTSTORM</h1>{status}</body></html>".encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache, must-revalidate")
        self.end_headers()
        if send_body:
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

    def _serve_apk(self, send_body=True):
        if not os.path.isfile(APK_PATH):
            self.send_error(404, "DARTSTORM.apk not found on server")
            return

        file_size = os.path.getsize(APK_PATH)
        range_header = self.headers.get("Range")

        start = 0
        end = file_size - 1
        status_code = 200

        if range_header:
            match = re.match(r"bytes=(\d+)-(\d*)", range_header)
            if match:
                start = int(match.group(1))
                if match.group(2):
                    end = int(match.group(2))
                if start >= file_size or end >= file_size or start > end:
                    self.send_response(416, "Requested Range Not Satisfiable")
                    self.send_header("Content-Range", f"bytes */{file_size}")
                    self.end_headers()
                    return
                status_code = 206

        content_length = end - start + 1

        self.send_response(status_code)
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Length", str(content_length))
        self.send_header("Content-Disposition", 'attachment; filename="DARTSTORM.apk"')
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Access-Control-Allow-Origin", "*")

        if status_code == 206:
            self.send_header("Content-Range", f"bytes {start}-{end}/{file_size}")

        self.end_headers()

        if not send_body:
            return

        chunk_size = 64 * 1024  # 64 KB chunks
        try:
            with open(APK_PATH, "rb") as f:
                f.seek(start)
                bytes_left = content_length
                while bytes_left > 0:
                    read_len = min(chunk_size, bytes_left)
                    chunk = f.read(read_len)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    bytes_left -= len(chunk)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def _serve_file(self, filepath, content_type, send_body=True):
        if not os.path.isfile(filepath):
            self.send_error(404, "File Not Found")
            return

        file_size = os.path.getsize(filepath)
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(file_size))
        self.send_header("Cache-Control", "no-cache, must-revalidate")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        if not send_body:
            return

        try:
            with open(filepath, "rb") as f:
                self.wfile.write(f.read())
        except (BrokenPipeError, ConnectionResetError):
            pass

    def log_message(self, format, *args):
        client_ip = self.client_address[0]
        sys.stdout.write(f"[{client_ip}] {format % args}\n")
        sys.stdout.flush()


class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    parser = argparse.ArgumentParser(description="DARTSTORM APK Download Server")
    parser.add_argument("port", nargs="?", type=int, default=DEFAULT_PORT, help="Listen port (default 8085)")
    args = parser.parse_args()

    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    server_address = ("0.0.0.0", args.port)
    httpd = ThreadedHTTPServer(server_address, DownloadHandler)
    local_ip = _detect_local_ip()
    print(f"DARTSTORM APK Download Server active on port {args.port}")
    if os.path.isfile(APK_PATH):
        print(f"Serving APK: {APK_PATH} ({os.path.getsize(APK_PATH):,} bytes)")
    else:
        print(f"Notice: {APK_PATH} not found yet (copy or build APK to serve downloads).")
    print(f"Local URL:   http://localhost:{args.port}/")
    if local_ip != "127.0.0.1":
        print(f"Network URL: http://{local_ip}:{args.port}/")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down download server.")
        httpd.server_close()


if __name__ == "__main__":
    main()
