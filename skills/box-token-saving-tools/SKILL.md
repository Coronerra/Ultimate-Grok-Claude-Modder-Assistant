---
name: Box token-saving tools
description: >-
  Use whenever a task on the shared box reads a log (Papyrus, SKSE, any big
  log), saved HTML or PDF, a long markdown doc, or fetches web pages from a
  script, so you read a compact version instead of the raw file.
---
# Box token-saving tools

Shared tools on the box live in `$KIT_HOME/tools/bin` (full notes: `$KIT_HOME/tools/README.md`). Non-interactive shells may not have them on PATH, so call full paths or run `source $KIT_HOME/tools/env.sh` first.

## Rules
1. **Logs:** before reading any Papyrus, SKSE or other large log, run `$KIT_HOME/tools/bin/logsum <log>`. It writes `<log>.summary.txt` beside the file and prints an error/warning summary (about 99% smaller). Read the summary first; open the raw log only at the specific lines you need (Read with offset/limit or `rg`). Don't use `rtk smart` or `rtk read` on logs.
2. **HTML and PDF:** before reading a saved web page or PDF, run `$KIT_HOME/tools/bin/tomd <file-or-url> [out.md]` and read the markdown.
3. **Long docs:** when you need only part of a long markdown doc, run `$KIT_HOME/tools/bin/chunk <md> [outdir]`, check `index.md`, and read only the relevant chunks.
4. **Web fetches in scripts:** in box Python, use `$KIT_HOME/tools/venv/bin/python` and `from boxkit import guarded_get` (6-hour SQLite cache, circuit breaker that stops after 3 failures, 30 s timeout), or `cached_session()` and `breaker(name)` separately. Never write unbounded retry loops.
5. **Change watching:** to watch files or URLs, use `$KIT_HOME/tools/bin/digest-watch --once` (writes a digest only on change), driven by an existing routine. Don't start `--schedule` as a background daemon.
6. **Habits:** skip status pings that carry no new info, don't reread full histories or files you already summarized, cap retries, and stay idle until there's real work.

## Safety
- Install from `$KIT_HOME/tools/requirements.txt` with `--require-hashes` only.
- Never install LiteLLM 1.82.7 or 1.82.8 (known malware). Stay on APScheduler 3.x. Don't install rtk-proxy (BUSL license).
