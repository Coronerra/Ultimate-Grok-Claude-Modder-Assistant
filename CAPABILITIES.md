# Capabilities

Everything the kit gives an end user, one line each. `install.sh` sets up the tools and skills in one step.

## Box tools (`tools/bin`, on PATH after `source tools/env.sh`)
- `logsum <log>`: summarizes Papyrus/SKSE/crash logs to errors/warnings (~99% smaller) via rtk oss.
- `tomd <file-or-url> [out]`: converts saved HTML/PDF/DOCX (or a URL, cached) to Markdown before a bot reads it.
- `chunk <md> [outdir]`: splits a long doc into indexed passages so a bot reads only what it needs.
- `digest-watch --once`: writes a digest only when watched files/URLs changed (template for routines).
- `devbench`: client for the DevBench HTTP API (health, inspect, console with capture, Papyrus call, raw).
- `whats-here`: read-only `look` / `near` / `ref` / `effects` / `watch` of the running game through DevBench (box-side: `DEVBENCH_URL`, optional `DEVBENCH_SOCKS`). Optional ToolkitProbe adds gaze, bounds and textures; the DLL is not bundled.
- `skyrim-winner`: which plugin wins a record (needs Node + xEdit on the Windows install). Ships the toolkit 4.2.0 wrong-record bugfix.
- `psenc`: encodes PowerShell for `-EncodedCommand` and optionally runs it on the PC over SSH.
- `socks5nc`: SOCKS5 ProxyCommand so SSH works through userspace Tailscale.
- `delegate-claude new|follow|review|status <package>`: hands a package job to Claude Code (the engineer) on the box, limited to the package folder, with no PC access, an allow-listed Bash, spend and turn caps, `GROK-WRITE` marker reporting, and a fresh read-only `review` that ends in `VERDICT: PASS/FIX`.
- `delegate-claude limits [--json|--probe|--clear]`: is the engineer available or blocked by a Claude usage limit, and until when; runs exit 3 while blocked so Grok knows to cover.
- `spriggit` (optional): wrapper for Mutagen Spriggit (plugin <-> YAML/JSON for text diffs).
- `champollion` (optional): wrapper for the Champollion Papyrus decompiler under Wine.
- `dream_archivetool` (optional): wrapper for the BSA/BA2 inspect/extract CLI.
- `tools/extras/inspect_plugin.py` (optional): read-only plugin record listing via bethkit.

## Python library (`tools/lib`)
- `claude_limits.py`: usage-limit detection and state for `delegate-claude` (`~/.claude-engineer/`).
- `boxkit`: `guarded_get()` / `cached_session()` / `breaker()`: 6 h SQLite HTTP cache, circuit breaker, hard timeout.

## Setup scripts
- `tools/install.sh`: venv in the kit, hash-pinned packages, PATH via env.sh + shell rc, skills into your chosen folder, smoke test; never edits tracked files.
- `tools/env.sh`: idempotent PATH/env setup (`KIT_HOME`, `KIT_LIB`, `KIT_CACHE`, `KIT_VENV`).
- `tools/requirements.txt`: hash-locked dependencies (markitdown, chonkie, requests-cache, pybreaker, APScheduler 3.x).

## Windows PC setup (`pc-setup/`)
- `install.bat` (top folder): checks prerequisites, asks Skyrim SE/AE or Skyrim VR, runs `pc-setup\setup.bat`, prints next steps and pauses.
- `setup.bat` + `setup.ps1`: one guided, ask-first (default No) setup of the gaming PC: Python 3, Git, Tailscale, OpenSSH Server + firewall, toolkit/staging/backups folders, game edition check (game folder, exe version, SKSE64 or SKSEVR loader, optional `game-profile.txt`), the bot's public key with locked ACLs, and a read-only summary of Tailscale IP, sshd and detected MO2/Skyrim paths; `-DryRun` supported.

## Skills (`skills/`)
- `getting-started-skyrim-modding`: first conversation; connect to the PC, one read-only mass-fix triage, one ranked fix list, guardrails and a retro-hacker warning voice.
- `remote-skyrim-modding-session`: start of every later session; connect, pre-launch checks, toolkit check, DevBench.
- `housecarl-data-layer-modding`: safe use of the houseCARL MCP server for records, conflicts and patches.
- `devbench-gfx-menu-testing`: read/set/call inside Scaleform menus through DevBench GFx.
- `skyrim-whats-here`: route “what am I looking at / what’s around me / what keeps happening” to `whats-here`.
- `triage-and-conflicts`: who-wins (`skyrim-winner`) and log triage, without touching load order.
- `skyrim-save`: read and investigate `.ess` / `.skse` saves; no save vault; ask before any write.
- `skyrim-nif`: mesh inspection and careful edits, including VR-critical PreWEAPON / PreSHIELD nodes.
- `skyrim-audio`: FUZ / XWM / WAV voice-line notes; ask before any write.
- `skyrim-bsa`: BSA/BA2 listing and extract; loose files override archives.
- `box-token-saving-tools`: always summarize/convert/chunk before reading; bounded web fetches.
- `delegate-to-claude-code`: when and how the coordinator hands work to Claude Code (everything but explicit writing, talk and deploys), fills GROK-WRITE markers, covers during usage limits, and updates `CLAUDE.md` after every job.
- `modding-tech-support`: be your own tech support. Grok collects crash, Papyrus and mod logs read-only; Claude Code diagnoses (REPORT.md with cause, fix, how to verify, and a ready-to-post bug report); Grok explains it in plain words.

## Team (top folder)
- `TEAM-RULES.md`: who's who, who writes what, GROK-WRITE markers, the no-minors hard line (fixed), and your own limits. Outranks every other file.
- `WHY-GROK-PLUS-CLAUDE.md`: why the team is Grok + Claude Code, what each one is for, and the flow.

## Docs (`docs/`)
- `CLAUDE-CODE-ENGINEER.md`: install Claude Code on the box, sign in without a browser (`claude setup-token`), configure, usage limits, smoke test, and what the safety rules do and don't cover.
- `WORKFLOW.md`: roles, hard PC rules, staging, SHA-256 verify, backups/rollback, hands-off load order.
- `INSTALLER-RUNBOOK.md`: step-by-step backup -> deploy -> re-hash -> confirm lists -> rollback.
- `REMOTE-SESSION.md`: every-session Tailscale + SSH routine and common fixes.
- `DEVBENCH-API.md`: DevBench endpoints (`/api/health`, `/api/tool/inspect|console|papyrus|gfx`) with placeholder host/port, plus What's here and newer tools.
- `whats-here.md`: box-side `whats-here` commands, gaps without ToolkitProbe, `--check` / `--textures` limits.
- `TOOLKIT-PROBE.md`: optional SKSE probe (not bundled); owner installs via the mod manager; needs DevBench 1.35+.
- `OPTIONAL-CLIS.md`: where to get Spriggit, Champollion, dream_archivetool, Caprica, papyrus-tools, with hashes.
- `CK-VR-SETUP.md`: Creation Kit for Skyrim VR via MO2 (Root Builder, CKPE, Papyrus sources, ESL/header notes, pitfalls).

## Templates (`templates/`)
- `CHANGES.template.md`: per-package change notes (what changed vs live, files, install, rollback, verify-in-game).
- `SHA256SUMS-HOWTO.md`: make/check checksums on Linux and PowerShell.
- `rollback.template.ps1`: Backup / Deploy / Restore with pre/new hash checks and process guard.
- `LOCATIONS.example.md`: shared location map pattern (FormID:plugin lookups, "already in X" tests, traps).
- `papyrus.toml`: starter config for papyrus-tools (`skse = true`).
- `CLAUDE.md.template`: the engineer's standing rules (package layout, hard rules, Papyrus checklist, project facts), copied to `<PACKAGES_DIR>/CLAUDE.md`.
- `bot-roster/`: roster example plus role cards for Installer, Researcher, Specialist, Chief of Staff and the Claude Code engineer bots.
