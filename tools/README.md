# Box tools

Read-side helpers for the bot's Linux box. They shrink logs and saved pages before a bot reads them, cache repeated HTTP fetches, fail fast when a host is down, and split long docs into passages. **They never deploy or edit game files**, and nothing here is installed on the modding PC.

Install: `bash tools/install.sh --skills-dir <DIR>` (one step; see `SETUP.md` A2). It never edits tracked files; Python tools re-exec under `tools/venv` (`KIT_VENV`).

| Path | What |
| --- | --- |
| `bin/logsum <log>` | `rtk log` wrapper: writes `<log>.summary.txt` (errors/warnings, ~99% smaller) and prints it. Needs rtk oss 1.2.0 (`RTK=` env, `bin/rtk`, or PATH). |
| `bin/tomd <file-or-url> [out.md]` | markitdown wrapper: HTML/PDF/DOCX/etc. → Markdown. URL fetches go through boxkit. |
| `bin/chunk <md> [outdir] [--chunk-size N]` | chonkie RecursiveChunker → `chunk-0001.md`…, `index.json`, `index.md`. No model download. |
| `bin/digest-watch --once --out D.md --state S.json <files/urls…>` | Writes a digest only when a source changed. `--schedule 15m` runs a **foreground** loop; don't daemonize by accident. |
| `bin/socks5nc <proxyhost:port> <host> <port>` | Minimal SOCKS5 ProxyCommand for SSH through userspace Tailscale. |
| `bin/devbench <health\|inspect\|console\|papyrus\|raw>` | DevBench HTTP API client (`DEVBENCH_URL`, `DEVBENCH_SOCKS`); see `docs/DEVBENCH-API.md`. |
| `bin/whats-here <look\|near\|ref\|effects\|watch>` | Read-only live observations through DevBench (`DEVBENCH_URL`, `DEVBENCH_SOCKS`); see `docs/whats-here.md`. |
| `bin/skyrim-winner` | Which plugin wins a record (toolkit 4.2.0 bugfix; needs Node + xEdit on the PC). |
| `bin/psenc [--ssh HOST [--run]] '<ps>'` | PowerShell -> UTF-16LE base64 `-EncodedCommand` (no quoting problems over SSH). |
| `bin/spriggit`, `bin/champollion`, `bin/dream_archivetool` | Optional wrappers; tools not bundled (`docs/OPTIONAL-CLIS.md`, `tools/vendor/`). |
| `extras/inspect_plugin.py` | Optional read-only plugin record listing (needs bethkit). |
| `lib/boxkit.py` | `cached_session()`, `breaker(name)`, `guarded_get(url, name=...)`: 6 h SQLite cache, circuit breaker (3 fails, 60 s reset), 30 s timeout. |
| `requirements.in` / `requirements.txt` | Top-level pins / hash-locked full set (`pip install --require-hashes`). |
| `bin/rtk.sha256` | Expected SHA-256 of the rtk oss 1.2.0 Linux binary (binary **not** included). |

Pinned: markitdown 0.1.9 `[pdf]`, chonkie 1.7.0, requests-cache 1.3.3, pybreaker 1.4.1, APScheduler 3.11.3.

## When to use which
- **Always `logsum` a Papyrus/SKSE/crash log before reading it.** Don't use `rtk smart` / `rtk read` on logs (they keep the whole file or drop error counts).
- **Always `tomd` saved HTML/PDF before reading.**
- **`chunk`** when you need only part of a long doc: read `index.md`, then only the relevant chunks.
- **`boxkit.guarded_get`** for every scripted web fetch. No unbounded retry loops.

## Hard rules
- Don't install `rtk-proxy` (BUSL). Use the Apache-2.0 oss CLI.
- Stay on APScheduler 3.x (not 4.x alpha).
- Install only with `--require-hashes`. Re-verify any new pin before adding it (e.g. LiteLLM 1.82.7 / 1.82.8 were malicious releases; never install those).
- Refresh pins: `pip-compile --generate-hashes --allow-unsafe --output-file tools/requirements.txt tools/requirements.in`.
