---
name: skyrim-whats-here
description: >-
  Read-only look / near / ref / effects / watch of a running Skyrim session
  through DevBench (and optional ToolkitProbe). Use when asked what the player
  is looking at, what is nearby, or what keeps affecting the character.
---
# What's here

Use `whats-here --help`. Commands: `look`, `near`, `ref`, `effects`, `watch`. They only read. They do not launch the game, run console commands, or change anything.

On the bot's box, reach DevBench the same way as `devbench`:

```bash
export DEVBENCH_URL=http://<TAILSCALE_IP>:<DEVBENCH_PORT>
export DEVBENCH_SOCKS=localhost:<SOCKS_PORT>   # only if the box uses userspace Tailscale
whats-here look --json
whats-here near --radius 500 --json
whats-here effects --json
whats-here watch --seconds 30 --json
```

`--game-dir` is optional when `DEVBENCH_URL` is set. `--textures` and `--check` need local access to the game folder and optional tools (House Carl / xEdit via `skyrim-winner`); without them the command still returns native DevBench results and lists the gaps.

## Route the question
- "What is this / its form ID?": `look`, then `ref` for that candidate. A nearby origin is not a confirmed gaze hit. If gaze is unavailable (no ToolkitProbe), say so; do not pretend the first nearby ref is what they pointed at.
- "Missing texture right here": `look --textures`, then `near --textures` if the owner is ambiguous. Compare shapes and bounds, not only origins.
- "Something keeps happening to me": `effects`, then `watch --seconds 180` for intermittent events. Timing matches on visuals are `inferred:timing`, never a direct engine link.

## Rules
- Read-only. Further disabling, removing, replacing or casting is outside this skill.
- Preserve `gaps`, coverage, truncation and timestamps. Different calls are not one atomic snapshot.
- Native refs/effects work without ToolkitProbe; VR gaze, shape bounds and some texture fields need the optional probe (DevBench 1.35+). The owner installs ToolkitProbe through their mod manager; this kit does not bundle the DLL. See `docs/TOOLKIT-PROBE.md` and `docs/whats-here.md`.
- Never edit `modlist.txt`, `plugins.txt` or `loadorder.txt`. Ask before each plugin edit. Only the Installer bot writes to the PC, after a backup and a re-hash.

The CLI and library are an attributed MIT copy of WingedGuardian's Skyrim AI Assistant Toolkit v4.2.0 What's here, with a transport adaptation for remote DevBench. Copyright (c) 2026 WingedGuardian; see `THIRD-PARTY-NOTICES.md`.
