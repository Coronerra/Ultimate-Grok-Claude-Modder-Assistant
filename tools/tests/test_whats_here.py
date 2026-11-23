#!/usr/bin/env python3
"""Box-side tests for whats-here: --help, and look/near/effects against a mock DevBench."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

KIT = Path(__file__).resolve().parents[2]
WHATS = KIT / "tools" / "bin" / "whats-here"
WINNER_TEST = KIT / "third-party" / "skyrim-ai-assistant-toolkit-4.2.0" / "tools" / "skyrim-winner.test.js"


class MockDevBench(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _send(self, payload, status=200):
        raw = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        if self.path == "/api/health":
            return self._send({"ok": True, "pid": 4242, "exe": "/tmp/mock/SkyrimVR.exe", "vr": True, "port": self.server.server_address[1]})
        if self.path == "/api/tools":
            return self._send({"tools": ["inspect", "forms"]})
        return self._send({"error": "not found"}, 404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length) or b"{}")
        if self.path == "/api/tool/inspect":
            kind = body.get("kind")
            if kind == "refs":
                return self._send({
                    "ok": True,
                    "refs": [
                        {"formId": "00000014", "name": "Player", "editorId": "PlayerRef", "formType": "Actor"},
                        {"formId": "0001A6A4", "name": "Mock Chair", "editorId": "MockChair", "formType": "Furniture"},
                    ],
                })
            if kind == "effects":
                return self._send({"ok": True, "activeEffects": [{"name": "MockEffect", "effect": {"formId": "00014A13"}}]})
            if kind == "mods":
                return self._send({"ok": True, "plugins": [{"index": 0, "name": "Skyrim.esm"}], "count": 1,
                                    "lightPlugins": [], "lightCount": 0, "total": 1})
            return self._send({"ok": True})
        if self.path == "/api/tool/forms":
            return self._send({"ok": True, "formId": body.get("formId"), "editorId": "MockForm"})
        return self._send({"error": "unknown tool"}, 404)


def start_server():
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), MockDevBench)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    return httpd


def run_whats(*args, env=None):
    cmd = [sys.executable, str(WHATS), *args]
    return subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=20)


def test_help():
    r = run_whats("--help")
    assert r.returncode == 0, r.stderr
    out = r.stdout + r.stderr
    for word in ("look", "near", "effects", "watch", "ref"):
        assert word in out, f"missing {word} in --help"


def test_requires_url_or_game_dir():
    env = os.environ.copy()
    env.pop("DEVBENCH_URL", None)
    env.pop("DEVBENCH_GAME_DIR", None)
    env.pop("KIT_GAME_DIR", None)
    r = run_whats("look", "--json", env=env)
    assert r.returncode == 2, r.stdout + r.stderr
    assert "DEVBENCH_URL" in (r.stdout + r.stderr)


def test_look_near_effects_against_mock():
    httpd = start_server()
    host, port = httpd.server_address
    try:
        env = os.environ.copy()
        env["DEVBENCH_URL"] = f"http://{host}:{port}"
        env.pop("DEVBENCH_SOCKS", None)
        for cmd in ("look", "near", "effects"):
            r = run_whats(cmd, "--json", "--timeout", "5", env=env)
            assert r.returncode == 0, f"{cmd} failed: {r.stdout}\n{r.stderr}"
            data = json.loads(r.stdout)
            assert data.get("ok") is True, data
            assert data.get("command") == cmd
            if cmd in ("look", "near"):
                ids = [row["formId"] for row in data.get("refs", [])]
                assert "00000014" in ids, data
            if cmd == "effects":
                assert data.get("native", {}).get("activeEffects"), data
            # Without ToolkitProbe the probe block is unavailable; that is expected.
            assert data.get("probe", {}).get("status") in ("unavailable", None) or "gaps" in data
    finally:
        httpd.shutdown()


def test_skyrim_winner_unit():
    r = subprocess.run(["node", str(WINNER_TEST)], capture_output=True, text=True, timeout=20,
                       cwd=str(WINNER_TEST.parent))
    assert r.returncode == 0, r.stdout + r.stderr


def main():
    tests = [test_help, test_requires_url_or_game_dir, test_look_near_effects_against_mock, test_skyrim_winner_unit]
    failed = 0
    for t in tests:
        try:
            t()
            print(f"  {t.__name__} ok")
        except Exception as exc:
            failed += 1
            print(f"  {t.__name__} FAILED: {exc}")
    if failed:
        sys.exit(1)
    print("all whats-here / winner tests passed")


if __name__ == "__main__":
    main()
