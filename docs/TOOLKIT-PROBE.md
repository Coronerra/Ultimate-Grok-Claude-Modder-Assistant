# ToolkitProbe (optional, not bundled)

ToolkitProbe is an optional SKSE plugin from WingedGuardian's [Skyrim AI Assistant Toolkit](https://github.com/WingedGuardian/skyrim-ai-assistant-toolkit). It adds gaze/hand ray, bounds, texture and capture detail to DevBench so `whats-here` can do more than native refs/effects.

**This kit does not ship the DLL, its source tree, or a build.** Get it from the upstream toolkit release (`ToolkitProbe.zip` on the [v4.2.0 release](https://github.com/WingedGuardian/skyrim-ai-assistant-toolkit/releases) or later). The plugin is MIT; it talks to DevBench through DevBench's MIT API.

## Install (owner, through the mod manager)
1. Confirm DevBench **1.35 or newer** is already installed and loading in the same MO2 instance (SE/AE or VR).
2. Download `ToolkitProbe.zip` from the upstream release. Do not copy files into `Data/` by hand.
3. Install the zip with your mod manager (MO2). Enable it in that same instance.
4. Launch through SKSE, then check `whats-here look --json` (or `devbench raw GET /api/tools`) for `probe.look` / `probe.near` and similar names.

Upstream notes: one DLL is built for SE, AE and VR; **live-tested on VR**, SE/AE experimental. Registration happens at `kDataLoaded` and needs DevBench 1.35+. If DevBench is missing or older, the plugin registers nothing. `RegisterTool` cannot undo a name collision; check the plugin log if tools are missing.

## Rules
- Optional. Say what it adds and let the owner choose.
- Only the Installer bot writes to the PC; the owner (or that installer, with a backup and a re-hash) puts it in MO2. Never write into `Data/` directly. Never edit `modlist.txt`, `plugins.txt` or `loadorder.txt`.
- `whats-here` stays useful without the probe; report the gaps.
