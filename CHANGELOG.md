# Changelog

## Ultimate Grok Claude Code Modder Assistant (v1.2) — 2026-11-24

Adds Claude Code as the team's engineer, alongside the Grok Bot as coordinator.
- **`TEAM-RULES.md`:** who's who and who writes what. Grok writes all explicit text, talks, plans and deploys; Claude Code does code, data, tech support, docs, packaging and reviews. Every fictional theme is the owner's call, with one fixed hard line: no sexual content involving minors, ever, enforced in code reviews (child checks are never removed). Owners can add their own limits.
- **`WHY-GROK-PLUS-CLAUDE.md`:** why the two are paired, and the flow from idea to install.
- **`tools/bin/delegate-claude`:** `new` / `follow` / `review` / `status` / `limits`. It runs Claude Code inside one package folder: no PC access, allow-listed Bash, spend and turn caps. Reviews run in a fresh read-only session ending in `VERDICT: PASS/FIX`. It also reports `[[GROK-WRITE: ...]]` markers where Grok must write explicit text.
- **Usage limits:** `tools/lib/claude_limits.py` detects Claude's session, weekly and model limits, records the reset time, and exits 3 so Grok knows to cover until the reset.
- **Skills:** `delegate-to-claude-code` (delegation, markers, covering during limits, keeping `CLAUDE.md` current) and `modding-tech-support` (self-service crash and log diagnosis that builds on `triage-and-conflicts` and `skyrim-whats-here`).
- **Bot access (PC setup):** running setup from an administrator account now warns that the bot would get full admin SSH access (valid for every admin account), and needs `ADMIN` typed to continue; Enter skips. `INSTALL.md` has step-by-step instructions for a separate **standard** Windows account for the bot, sharing only the MO2 instance (read), its `mods` folder (modify) and the game's My Games folder (read). README safety model updated.
- **Templates and docs:** `templates/CLAUDE.md.template`, `templates/bot-roster/claude-code-engineer.md`, `docs/CLAUDE-CODE-ENGINEER.md` (install, `claude setup-token`, smoke test, what the safety rules cover). Cover art in `assets/cover.jpg`.

## v1.1 — 2026-11-23

- **What's here** (`whats-here`): read-only `look`, `near`, `ref`, `effects` and `watch` through DevBench, for use from the bot's box (`DEVBENCH_URL`, optional `DEVBENCH_SOCKS`). Attributed MIT copy of WingedGuardian toolkit v4.2.0, with a transport adaptation for remote DevBench. Skill: `skills/skyrim-whats-here`. Guide: `docs/whats-here.md`.
- **skyrim-winner 4.2.0 bugfix:** a plugin plus a short record ID no longer traces the wrong record when that plugin also overrides a master with the same low bytes. Wrapper: `tools/bin/skyrim-winner`.
- Short skill docs for triage and conflicts, saves, NIFs, audio and BSA archives, written for this kit's rules (Installer-only writes, backup then re-hash, never edit load-order files, ask before each plugin edit). Useful facts taken from toolkit 4.2.0 skill text; no skyguard, save vault, vr-headless, setup.sh, or houseCARL gateway.
- **ToolkitProbe** documented only (`docs/TOOLKIT-PROBE.md`). The DLL is not bundled. The owner installs it through their mod manager; it needs DevBench 1.35+.
- DevBench API notes updated for newer tools (`forms`, window focus / alwaysActive) and for What's here.
- `THIRD-PARTY-NOTICES.md` records the copied toolkit files, copyright and MIT license.

## v1.0 — 2026-11-23

- First public release: SE/AE and VR installer (`install.bat`), box tools, five skills, templates and docs.
