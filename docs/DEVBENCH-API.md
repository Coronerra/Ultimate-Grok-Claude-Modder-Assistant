# DevBench HTTP API: how the bot uses it

DevBench (alandtse; GPL-3.0 with modding/linking exceptions) is a **dev-only** SKSE plugin that serves a small HTTP API while the game runs. The bot uses it to read live state and, with the owner's OK, to run console commands or Papyrus calls while the owner plays. Install it through MO2 (see `SETUP.md` Part D). Field names below match the documented examples; check your DevBench version's docs, and prefer a connected DevBench tool/schema when your bot has one.

Placeholders: `<TAILSCALE_IP>` (the PC's tailnet IP or MagicDNS name), `<DEVBENCH_PORT>` (from your DevBench config; SE/AE and VR builds use different defaults), `<SOCKS_PORT>` (the box's userspace-Tailscale SOCKS5 port).

## 0. Expose and reach it
On the PC, only while testing and only to the tailnet:
```powershell
tailscale serve --bg --tcp <DEVBENCH_PORT> tcp://127.0.0.1:<DEVBENCH_PORT>
# afterwards:
tailscale serve --tcp <DEVBENCH_PORT> off
```
On the box:
```bash
export DEVBENCH_URL=http://<TAILSCALE_IP>:<DEVBENCH_PORT>
export DEVBENCH_SOCKS=localhost:<SOCKS_PORT>      # omit if the box has a real tailnet interface
devbench health                                   # GET /api/health
```

## 1. Endpoints (curl form)
All tool calls are `POST /api/tool/<tool>` with a JSON body.
```bash
DB="curl -sS -m 15 --socks5-hostname localhost:<SOCKS_PORT> -H Content-Type:application/json"

# Health
$DB http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/health

# Read-only inspect: game state, loaded mods (compare with the MO2 profile), nearby refs
$DB http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/tool/inspect -d '{"kind":"state"}'
$DB http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/tool/inspect -d '{"kind":"mods"}'
$DB http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/tool/inspect -d '{"kind":"refs","formType":"Actor","limit":50}'

# Console command, with output captured and returned
$DB http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/tool/console \
  -d '{"action":"exec","command":"getav health","capture":true}'

# Papyrus call: Script.Function on a "self" form, with args
$DB http://<TAILSCALE_IP>:<DEVBENCH_PORT>/api/tool/papyrus \
  -d '{"action":"call","script":"Actor","function":"GetActorValue","self":{"form":"00000014"},"args":["Health"]}'
```
`00000014` is the player. For your own plugin's forms, pass the form the way your DevBench version documents (runtime FormID, or plugin + local ID). **Never hard-code a runtime FormID in shipped scripts**; load-order prefixes change.

Same calls with the kit's client:
```bash
devbench console "getav health"
devbench papyrus Actor GetActorValue --self 00000014 --args '["Health"]'
devbench inspect refs --json '{"formType":"Actor","limit":50}'
devbench raw POST /api/tool/gfx '{"...":"see devbench-gfx-menu-testing skill"}'
whats-here look --json
whats-here effects --json
```

Newer DevBench builds (1.29–1.32, documented but not all live-tested here) add `forms` (`find` / `describe`), `actor` idle tools, `capture`, `inspect kind=draws`, difficulty and `alwaysActive` / `windowFocused` on `inspect kind=state` (a background window with `bAlwaysActive` off can stop advancing). `whats-here` uses `inspect` and `forms describe`. ToolkitProbe (optional, DevBench **1.35+**) registers `probe.look` / `probe.near` and related tools; see `docs/TOOLKIT-PROBE.md` and `docs/whats-here.md`.

## 2. Rules
1. **Read before you change, read back after.** Inspect first; after any console/Papyrus change, inspect again and report the actual result.
2. Console and Papyrus calls change the **live session** (and can end up in the save). Only with the owner's OK, while they're playing and watching. Never run `save`/`qqq`-type commands, mod-uninstall or "reset" commands without an explicit request.
3. Keep calls cheap: one call per question, short timeouts (8-15 s), no tight polling loops. Use `boxkit.breaker()` style fail-fast in scripts (stop after 3 failures).
4. A DevBench result proves runtime behavior **in this session** only. Record it in CHANGES.md as "verified live via DevBench" with what was checked.
5. Turn `tailscale serve` off when done. Never expose the port to the public internet (no Funnel).
6. Menu internals (Scaleform) need DevBench GFx: load the `devbench-gfx-menu-testing` skill.
7. `whats-here` is read-only. Prefer it for “what am I looking at / what’s around me / what keeps happening” instead of ad-hoc console commands.
