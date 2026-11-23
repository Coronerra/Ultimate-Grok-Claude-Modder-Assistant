---
name: Remote Skyrim modding session
description: >-
  Use at the start of any Skyrim modding session on a user's Windows PC reached
  over Tailscale + SSH, with the Claude Code modding toolkit and DevBench.
---
# Remote Skyrim modding session

Goal: every session on any of the user's Skyrim PCs starts the same, verified way. Host names, paths, and which PC is which live in memory, not here.

## 1. Connect
1. Make sure tailscaled is running on my computer (userspace mode, SOCKS5 on localhost:<SOCKS_PORT>). If not, start it with the saved state file; `tailscale status` should list the target PC.
2. Pick the PC the user is at (ask only if unclear). Test `ssh <host> ver` (ProxyCommand through the SOCKS proxy). If SSH fails, have the user check that Tailscale is signed in and that `sshd` is running.

## 2. Check the setup before launch (read-only)
1. Game exe version, SKSE version, and Address Library match.
2. Active MO2 profile: modlist.txt enabled count, plugins.txt full vs light counts (stay under 254 full), missing masters.
3. New logs since last session: SKSE logs, Crash Logger crash-*.log, Papyrus.0.log (recurring errors, suspended-stack dumps), mod plugin logs. Note logs under OneDrive\Documents if Documents is redirected.
4. Compare against last session's notes in memory and report only what changed or what's broken, most important first.

## 3. Toolkit
1. In the toolkit folder (game root), run `tools/toolchain-check.sh` through Git Bash. Report any tool that fails.
2. Occasionally check the toolkit's GitHub for a newer release. Never update without the user's OK.
3. If houseCARL is present, load the `housecarl-data-layer-modding` skill before relevant record, conflict, asset or distributor work. Distinguish its staged package from its installed host version and from the custom Grok kit. Verify connector access and game-edition support; package presence alone does not establish either. Prefer a new-patch workflow when using its writers.

## 4. DevBench (live game)
1. The user launches the game through SKSE in MO2 and loads a save. On the PC, `tailscale serve --bg --tcp <DEVBENCH_PORT> tcp://127.0.0.1:<DEVBENCH_PORT>` exposes it (check the port in your DevBench config; SE/AE and VR builds use different defaults); make network exposure changes only when authorized.
2. Probe `GET http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/health` through the SOCKS proxy, then `ping`. Use `inspect kind=mods` to confirm the load order matches the profile.
3. Test fixes live (console, inspect, papyrus call, scenario) while the user plays.
4. For reading or interacting with Scaleform menu internals, load `devbench-gfx-menu-testing`. Verify DevBench GFx is installed, enabled and responding in this instance. Read before changing and read back afterward; installation alone does not prove runtime compatibility.

## Rules
- Never copy files into Data/ directly. Mods (including DevBench) get installed through the mod manager. New or changed mods go into a new MO2 mod folder, after the user approves.
- Back up any file before editing it, and preview ESP changes (dry run) first.
- houseCARL `in_place=` writes are documented to keep no backup and have no undo; require explicit user approval and a separate verified backup before using them.
- The user isn't a coder: give exact copy-paste steps for anything they have to do, one step at a time.
- Save new facts (paths, versions, project status) to memory at the end of the session.
