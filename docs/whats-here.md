# What's here

`whats-here` (`look`, `near`, `ref`, `effects`, `watch`) reads a running Skyrim session through DevBench. It answers what the player is looking at, what is nearby, and what is affecting the character. **Read-only.** It never starts the game or changes it.

The command is an attributed MIT copy of WingedGuardian's [Skyrim AI Assistant Toolkit](https://github.com/WingedGuardian/skyrim-ai-assistant-toolkit) v4.2.0 What's here, plus a small transport adaptation so a bot box can reach DevBench over Tailscale (`DEVBENCH_URL`, optional `DEVBENCH_SOCKS`). See `THIRD-PARTY-NOTICES.md`.

Upstream live-tested the probe path on Skyrim VR; SE/AE share the source but were still experimental in 4.2.0. Real headset and hand pointing may be untested even when gaze tools are present.

## On the bot's box

```bash
export DEVBENCH_URL=http://<TAILSCALE_IP>:<DEVBENCH_PORT>
export DEVBENCH_SOCKS=localhost:<SOCKS_PORT>    # omit if the box has a real tailnet interface
whats-here --help
whats-here look --json
whats-here near --radius 500 --json
whats-here effects --json
whats-here watch --seconds 30 --json
```

`--game-dir` can be omitted in this mode. Exit codes: `0` complete, `3` observed but incomplete, `2` failed.

Without ToolkitProbe, native DevBench `inspect refs` / `inspect effects` still run. Nearby distances then use reference origins, not geometry bounds, and VR gaze is unavailable. Say that plainly. With the probe (optional SKSE plugin, DevBench 1.35+), `look` can use HMD or hand rays and `near` can use bounds. The owner installs the probe through their mod manager; this kit does not ship the DLL (`docs/TOOLKIT-PROBE.md`).

`--textures` and `--check` try optional local helpers (House Carl gateway, `skyrim-winner` + xEdit). This kit does not include the toolkit's houseCARL gateway. If those helpers are absent, the command reports gaps and still returns the native/probe observations. `--check` is capped at 12 forms (each one loads the full order in xEdit).

`watch` may infer a source for a visual from magic effects applied up to 1 s earlier (`inferred:timing`). That is timing evidence, not an engine link.

`look` will attach an unparsed `last-pick.json` from "What Am I Looking At" (SE/AE, Nexus 199906) when one exists under `Data/SKSE/Plugins`. It is a separate observation, not a confirmation of gaze.
