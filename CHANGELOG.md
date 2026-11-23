# Changelog

## v1.1 — 2026-11-23

- **What's here** (`whats-here`): read-only `look`, `near`, `ref`, `effects` and `watch` through DevBench, for use from the bot's box (`DEVBENCH_URL`, optional `DEVBENCH_SOCKS`). Attributed MIT copy of WingedGuardian toolkit v4.2.0, with a transport adaptation for remote DevBench. Skill: `skills/skyrim-whats-here`. Guide: `docs/whats-here.md`.
- **skyrim-winner 4.2.0 bugfix:** a plugin plus a short record ID no longer traces the wrong record when that plugin also overrides a master with the same low bytes. Wrapper: `tools/bin/skyrim-winner`.
- Short skill docs for triage and conflicts, saves, NIFs, audio and BSA archives, written for this kit's rules (Installer-only writes, backup then re-hash, never edit load-order files, ask before each plugin edit). Useful facts taken from toolkit 4.2.0 skill text; no skyguard, save vault, vr-headless, setup.sh, or houseCARL gateway.
- **ToolkitProbe** documented only (`docs/TOOLKIT-PROBE.md`). The DLL is not bundled. The owner installs it through their mod manager; it needs DevBench 1.35+.
- DevBench API notes updated for newer tools (`forms`, window focus / alwaysActive) and for What's here.
- `THIRD-PARTY-NOTICES.md` records the copied toolkit files, copyright and MIT license.

## v1.0 — 2026-11-23

- First public release: SE/AE and VR installer (`install.bat`), box tools, five skills, templates and docs.
