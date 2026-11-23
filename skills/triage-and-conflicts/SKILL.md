---
name: triage-and-conflicts
description: >-
  Figure out which plugin wins a record, and triage Papyrus or crash logs,
  without touching load order. Use for override/conflict questions and log analysis.
---
# Triage and conflicts

Start read-only. One ranked list of findings, then wait for the owner's go before any write.

## Who wins a record
`skyrim-winner` (attributed toolkit 4.2.0, MIT) answers "which plugin actually wins this record?" against a full load order via xEdit, on the Windows install. A plugin plus a short record ID used to be able to trace the wrong record (a master override with the same low bytes). The 4.2.0 copy in this kit fixes that.

```bash
skyrim-winner chain <formid> [plugin]
skyrim-winner winner <formid> [plugin]
```

Needs Node and xEdit's library on the PC. If you cannot run it, say so and use houseCARL or xEdit by hand instead of guessing.

## Logs
Always shrink Papyrus / SKSE / crash logs with `logsum` before reading (`box-token-saving-tools`). Report errors and warnings, then the likely cause, then a ranked fix list.

## Hard rules (this kit)
- Never edit `modlist.txt`, `plugins.txt` or `loadorder.txt`. Load order advice is advice only; the owner's mod manager owns the order.
- Ask the owner before each plugin edit.
- Only the Installer bot writes to the PC. Back up first, SHA-256 every file, re-hash after, and leave a rollback script.
- Do not install or copy files into `Data/`. Mods and SKSE plugins go through the owner's mod manager (MO2).
- This kit does not ship LOOT auto-sort, a houseCARL gateway, or "install this archive" tools.

Useful facts from WingedGuardian toolkit v4.2.0 docs (not bundled here): a read-only LOOT advisor must never write the load-order files; a missing-texture check that cannot finish the archive list must not report "none missing".
