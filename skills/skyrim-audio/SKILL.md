---
name: skyrim-audio
description: Process Skyrim voice and sound files (FUZ, XWM, WAV). Use when replacing or inspecting a voice line.
---
# Audio files

Skyrim voice files are `.fuz`, a container holding:

- **XWM** — compressed audio (XWMA)
- **LIP** — lip-sync data for NPC faces

To replace a line: WAV → XWM → FUZ (keep the matching LIP if lip-sync is needed). Ask before any write. Stage, hash, back up, re-hash. Only the Installer bot writes to the PC. Never write into `Data/` directly.

This kit does not bundle AutoMod. If an audio CLI is already installed, prefer `--json` and a dry run. Copyright-bearing voice assets are not republished.

Short structure notes follow WingedGuardian toolkit v4.2.0 audio skill docs (MIT).
