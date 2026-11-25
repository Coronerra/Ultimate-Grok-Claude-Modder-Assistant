---
name: Modding tech support
description: >-
  Use when the owner has a problem with their own game or a mod: a crash, a
  CTD on load or save, a mod that doesn't work, a missing master, an MCM that
  won't show, scenes that never start, Papyrus errors, or "is this mod
  compatible with that one?". Grok collects the evidence read-only, Claude
  Code diagnoses it, and Grok explains the answer and the fix in plain words.
  The goal: the owner never has to chase a mod author for help.
---
# Modding tech support

The owner is their own tech support now, and we're the team behind them. This skill is the full support flow. It builds on `triage-and-conflicts` (who wins a record with `skyrim-winner`, and log triage rules) and, with DevBench, `skyrim-whats-here` (what's in front of the player right now). I (Grok) talk and collect, Claude Code diagnoses, and the owner decides. Everything starts **read-only**. A fix only happens as a normal staged package after the owner's own go (`docs/WORKFLOW.md`).

## 1. Ask, briefly (one message)
- What happened, and when? (main menu, loading a save, a certain place, starting a scene, opening the MCM)
- What changed since it last worked? (a new or updated mod, a load-order change, a game or SKSE update)
- Can they make it happen again?
Then go and look. Don't make them answer a questionnaire.

## 2. Collect the evidence (read-only, on the PC)
Use `remote-skyrim-modding-session` to connect, then pull copies to the box into a new support package, `support-<topic>-<yyyymmdd>/live/`:
- The newest **crash log** (Crash Logger SSE/AE: `crash-*.log`; or NetScriptFramework), if it crashed.
- **`Papyrus.0.log`** (if logging is off, say how to turn it on: `bEnableLogging=1`, `bEnableTrace=1` under `[Papyrus]` in `Skyrim.ini`), plus SKSE logs (`skse64.log`, the plugin logs in `Documents\My Games\Skyrim Special Edition\SKSE\`).
- The **mod's own log** if it has one (many adult and SkyrimNet-related mods write their own `.log` in `SKSE\Plugins\`).
- The active MO2 profile's `plugins.txt` and `modlist.txt` (copies only; never edit the live files).
- Versions: game exe, SKSE, Address Library, and the mod's version.
- The mod's own docs, if it ships any: its README, `AI_CONTEXT.md` or `CLAUDE.md`, and changelog. Often the answer is already in there.
- With DevBench running, a `whats-here look` / `near` / `effects` snapshot of the problem spot (`skyrim-whats-here`), saved into `live/`.
- For an override or conflict question, the `skyrim-winner chain <formid> [plugin]` output for the records involved (`triage-and-conflicts`), saved into `live/`.
Hash everything in `live/` (`cd live && find . -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS`). Run `logsum` on big logs and keep both files.

## 3. Hand the diagnosis to Claude Code
Write `<support-package>/TASK.md`:
```
Goal: diagnose <symptom>. Don't fix anything yet.
What the owner says: <their words>
Evidence in live/: <list>. Mod sources or docs (read-only): <--ref folders, if any>
Done means: stage/REPORT.md with
  1. most likely cause, with the exact log lines that show it
  2. other possible causes, ranked
  3. the fix: what to change, where, and whether it's a load-order / install / settings / code fix
  4. how to confirm it's fixed in game
  5. what to tell the mod author IF it's a real bug in their mod (a ready-to-post report: versions, steps, log lines)
Out of scope: changing anything. Read-only diagnosis.
```
```bash
delegate-claude new <support-package> --task-file <support-package>/TASK.md [--ref <mod-source-or-docs>]
```
- If `delegate-claude` exits **3** (usage limit), check `delegate-claude limits`. If the engineer is out, do the diagnosis myself from the `logsum` output, and say it wasn't engineer-checked.
- For a crash log, Claude Code should name the module (`.dll`) and the plugin/form or script on the stack, plus what that usually means (missing master, a bad mesh or skeleton, an SKSE plugin built for the wrong game version, a Papyrus overload).

## 4. Explain it to the owner, in plain words
Short and in order:
1. **What's wrong** (one sentence) and how sure we are.
2. **The fix**, as numbered steps. Say who does it: the owner in MO2, or our team as a staged package.
3. **How to check it worked.**
4. Only if it's a genuine bug in someone else's mod: the ready-to-post bug report from REPORT.md, so the owner sends one complete report instead of a vague "it's broken".

## 5. If a fix needs files changed
Turn it into a normal package: `delegate-claude follow <support-package> --task "Build the fix from REPORT.md, option <n>"`, then `review`, then the owner's go, then the Installer deploys. **Load-order fixes are done by the owner in MO2 (or LOOT),** never by hand-editing `plugins.txt`.

## Common causes worth checking first
- A **missing or disabled master**, or a master loading after the plugin that needs it.
- **Version mismatch:** an SKSE plugin built for a different game version (SE 1.5.97 vs AE 1.6.x vs VR), Address Library missing, or an SKSE version that doesn't match the game.
- A **full-plugin count** over 254 (ESL-flag what can be flagged, or merge).
- A **required framework missing or outdated** (OStim Standalone, SexLab, SkyUI, PapyrusUtil, powerofthree's Papyrus Extender, JContainers, MCM Helper, SkyrimNet).
- **Scripts not running:** the mod's quest never started (check its log header), its MCM never registered (`setstage SKI_ConfigManagerInstance 1` in the console), or the save holds old script versions after an update (does the mod say to update on a clean save?).
- **Conflicting overrides:** two mods editing the same record (check with `skyrim-winner`, xEdit or `tools/extras/inspect_plugin.py`), or two mods doing the same job at once (two defeat mods, two SkyrimNet bridges).
- **Body, skeleton or animation mismatch:** XPMSSE or skeleton version, missing behavior files (run Pandora, Nemesis or FNIS again), or a body mod without its physics or HDT.

## Don't
- Don't guess when the logs can tell us. Collect first.
- Don't edit `plugins.txt`, `loadorder.txt`, `modlist.txt` or `Data\` by hand.
- Don't send raw multi-megabyte logs to anyone. `logsum` first.
- Don't judge the owner's mod list. It's their game.
- Hard line still applies: if a "fix" means enabling sexual content involving children (e.g. removing a child check), refuse and say why in one line.
