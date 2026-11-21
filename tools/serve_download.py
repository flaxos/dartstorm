#!/usr/bin/env python3
"""ZeroTier APK Download Server for DARTSTORM.

Binds natively to host port 8085 (0.0.0.0:8085) so mobile devices connected
via ZeroTier (192.168.193.11:8085) can download DARTSTORM.apk reliably without
Docker bridge routing or proxy issues.

Features:
- Native Range header support (HTTP 206 Partial Content) for resilient mobile downloads
- Proper Android APK MIME type and Content-Disposition headers
- Route aliases: /, /apk, /download, /DARTSTORM.apk
- Multi-threaded request handling
"""

import http.server
import os
import re
import socketserver
import sys
import urllib.parse

PORT = 8085
DOWNLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "download"))
APK_PATH = os.path.join(DOWNLOAD_DIR, "DARTSTORM.apk")
HTML_PATH = os.path.join(DOWNLOAD_DIR, "index.html")


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
            self._serve_file(HTML_PATH, "text/html; charset=utf-8", send_body)
        elif path.endswith("DARTSTORM.apk") or path in ("/download/DARTSTORM.apk", "/apk/DARTSTORM.apk"):
            self._serve_apk(send_body)
        else:
            # Try serving from download directory
            rel_path = parsed.path.lstrip("/")
            file_path = os.path.join(DOWNLOAD_DIR, rel_path)
            if os.path.isfile(file_path):
                self._serve_file(file_path, "application/octet-stream", send_body)
            else:
                self.send_error(404, f"File Not Found: {self.path}")

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
    server_address = ("0.0.0.0", PORT)
    httpd = ThreadedHTTPServer(server_address, DownloadHandler)
    print(f"DARTSTORM APK Download Server active on port {PORT}")
    print(f"Serving APK: {APK_PATH} ({os.path.getsize(APK_PATH):,} bytes)")
    print(f"ZeroTier URL: http://192.168.193.11:{PORT}/")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down download server.")
        httpd.server_close()


if __name__ == "__main__":
    main()
