"""Read-only git smart-HTTP server for the local ArgoCD.

Serves the moonrepo working copy's .git at http://<host>:8930/moonrepo so the
VM's ArgoCD can fetch the `dev` jj bookmark. Only git-upload-pack (fetch/clone)
is implemented — pushes are impossible by construction.

Run: uv run python git_server.py  (stdlib only, no dependencies)
"""

import gzip
import pathlib
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

REPO = pathlib.Path(__file__).resolve().parents[2]  # the moonrepo root
BIND = ("0.0.0.0", 8930)
SERVICE = "git-upload-pack"


def pkt_line(data: bytes) -> bytes:
    return f"{len(data) + 4:04x}".encode() + data


class GitHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, body: bytes, content_type: str) -> None:
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def _reject(self, code: int, msg: str) -> None:
        self.send_error(code, msg)

    def do_GET(self) -> None:
        url = urlparse(self.path)
        service = parse_qs(url.query).get("service", [None])[0]
        if url.path != "/moonrepo/info/refs":
            return self._reject(404, "only /moonrepo is served")
        if service != SERVICE:
            return self._reject(403, "read-only server: upload-pack only")
        refs = subprocess.run(
            ["git", "upload-pack", "--stateless-rpc", "--advertise-refs", str(REPO)],
            capture_output=True,
            check=True,
        ).stdout
        body = pkt_line(f"# service={SERVICE}\n".encode()) + b"0000" + refs
        self._send(body, f"application/x-{SERVICE}-advertisement")

    def do_POST(self) -> None:
        if self.path != f"/moonrepo/{SERVICE}":
            return self._reject(403, "read-only server: upload-pack only")
        length = int(self.headers.get("Content-Length", 0))
        request = self.rfile.read(length)
        if self.headers.get("Content-Encoding") == "gzip":
            request = gzip.decompress(request)
        result = subprocess.run(
            ["git", "upload-pack", "--stateless-rpc", str(REPO)],
            input=request,
            capture_output=True,
        )
        if result.returncode != 0:
            return self._reject(500, result.stderr.decode(errors="replace")[:500])
        self._send(result.stdout, f"application/x-{SERVICE}-result")

    def log_message(self, fmt, *args):  # noqa: D102 - quieter logs
        print(f"{self.address_string()} {fmt % args}")


if __name__ == "__main__":
    print(f"serving {REPO} (read-only) at http://{BIND[0]}:{BIND[1]}/moonrepo")
    ThreadingHTTPServer(BIND, GitHandler).serve_forever()
