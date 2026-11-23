# Third-party notices

## Skyrim AI Assistant Toolkit v4.2.0 (WingedGuardian)

Copyright (c) 2026 WingedGuardian

License: MIT. The full license text is in
`third-party/skyrim-ai-assistant-toolkit-4.2.0/LICENSE`.

Source: https://github.com/WingedGuardian/skyrim-ai-assistant-toolkit
Version shipped here: v4.2.0 (2026-11-22).

### Files copied into this kit
- `third-party/skyrim-ai-assistant-toolkit-4.2.0/tools/whats-here.py`
- `third-party/skyrim-ai-assistant-toolkit-4.2.0/tools/whats_here/`
- `third-party/skyrim-ai-assistant-toolkit-4.2.0/tools/skyrim-winner.js`
- `third-party/skyrim-ai-assistant-toolkit-4.2.0/tools/skyrim-winner.sh`
- `third-party/skyrim-ai-assistant-toolkit-4.2.0/tools/skyrim-winner.test.js`

`skyrim-winner.js` includes the v4.2.0 bugfix: given a plugin and a short record ID, the tool no longer traces a master record that shares the same low bytes.

### Adaptations (copyright retained; still MIT)
Documented in `third-party/skyrim-ai-assistant-toolkit-4.2.0/SOURCE.txt`:

- `transport.py` accepts `DEVBENCH_URL` and optional `DEVBENCH_SOCKS` so a bot box can reach DevBench over Tailscale, and skips local exe checks in that mode.
- `cli.py` allows omitting `--game-dir` when `DEVBENCH_URL` is set.
- `enrichment.py` `--check` looks for `skyrim-winner.sh` in this kit (or `SKYRIM_WINNER_SH` / `KIT_WINNER_SH`), not only `<game-dir>/tools/`.

Kit wrappers: `tools/bin/whats-here`, `tools/bin/skyrim-winner`.

### Not copied
ToolkitProbe.dll and its build tree, skyguard, the save vault, vr-headless, `setup.sh`, and the toolkit's houseCARL gateway are **not** included. ToolkitProbe is documented only, in `docs/TOOLKIT-PROBE.md`.

Skill docs under `skills/` named after toolkit skills (`skyrim-whats-here`, `triage-and-conflicts`, `skyrim-save`, `skyrim-nif`, `skyrim-audio`, `skyrim-bsa`) are original short write-ups for this kit. They keep this kit's safety rules and note facts taken from the v4.2.0 skill text.
