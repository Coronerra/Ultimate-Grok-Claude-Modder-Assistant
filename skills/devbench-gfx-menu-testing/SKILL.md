---
name: DevBench GFx menu testing
description: >-
  When a live Skyrim session with DevBench needs to read, set or call something
  inside an open Scaleform menu (RaceMenu, HUD, MCM or another mod's menu), or
  confirm a menu/UI fix, read this before sending menu input.
---
# DevBench GFx menu testing

DevBench GFx is a separate SKSE DLL adding a `gfx` tool to DevBench, not part of houseCARL or the custom toolkit. Source documentation: [Nexus mod 198173](https://www.nexusmods.com/skyrimspecialedition/mods/198173). Requires DevBench, SKSE and Address Library. Install through MO2. Machine-specific paths and versions belong in memory.

## Before use
1. Confirm the intended MO2 instance/profile has both DevBench and GFx enabled. Separate SE/AE and VR instances must not be confused.
2. Have the user launch through SKSE in MO2 and load a test save before mutations. Do not launch or alter a live session unsolicited.
3. Follow remote-skyrim-modding-session for connectivity and health checks. Verify the actual configured port (`<DEVBENCH_PORT>`; DevBench documents different defaults for SE/AE and VR) and that gfx is listed. Prefer a connected DevBench tool when available; discover its current schema. Otherwise use its documented POST /api/tool/gfx endpoint through the established authorized connection. Do not change network exposure without approval.
4. If gfx is absent, inspect current SKSE/DevBench logs; enabled DLL presence does not prove loading.

## Documented operations
JSON request shapes; M, P and V below are placeholders, not literal values:
- get: {"op":"get","menu":M,"path":P,"depth":2,"limit":500}.
- set: {"op":"set","menu":M,"path":P,"value":V}.
- call: {"op":"call","menu":M,"path":P,"args":[...]}.
- batch: up to 64 get/set/call steps; stops on first failure with failedIndex. Consult installed documentation for the exact batch envelope rather than guessing.
Paths start at _root or _global, use dotted members and numeric array indexes. Menu is the engine menu name, such as RaceSex Menu. get depth maximum is 8; enumeration stops at 20,000 values and reports truncated. Methods appear as {}.

## Workflow
Read first and record prior values, perform only the requested set/call, then read again and report the actual result. Indexes and paths can differ between menus and UI replacers; never infer them from another setup. A batch is not a transaction and has no rollback: earlier steps may have landed before failure. Steps time out at 3 seconds and may still finish afterward; re-read before retrying any mutation. Keep a test-save rollback for changes with gameplay effects. A returned value does not prove the visual result; confirm appearance with the user.

## Evidence and limits
The author reports testing AE 1.7.104 under CrossOver/macOS with DevBench 1.32.0, not Windows, SE or VR. Verify locally rather than promising compatibility. Installed/enabled, loaded, responding, read-back verified and visually verified are separate states. After RaceMenu onItemPress race changes, the author's note says equipState can be stale; inspect listState.activeEntry. This tool reads and invokes existing menu content; it does not create arbitrary new interface features.
