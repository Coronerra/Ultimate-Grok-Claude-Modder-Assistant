---
name: skyrim-save
description: >-
  Read and investigate Skyrim save files (.ess / .skse). Use for orphaned
  scripts, mod footprint, bloat, or before any save change. This kit does not
  include a save vault.
---
# Save files

Read first. Never delete, move, overwrite or "clean" a save without the owner's explicit go, and never while the game is running.

## Reading
The kit does not bundle a save parser. Use ReSaver (Nexus, Apache-2.0) or the box `resaver` CLI if it is already installed. Note player name, level, location, plugin count, and any script or FormID hits you were asked to find.

SSE/VR saves use LZ4. A raw byte hit is a lead, not proof of an orphaned script or an active effect. Structured ReSaver output is the next step.

## Changing a save
This kit does **not** include the toolkit 4.x save vault, and you must not add it. If a change is approved:

1. Copy the `.ess` and matching `.skse` to a backup the owner can see, and SHA-256 both.
2. Preview any ReSaver write (no `--apply` / no overwrite of the live pair).
3. Write a new pair, never over the original, unless the owner asked to replace and the backup is confirmed.
4. Re-hash and report the new hashes.

Do not run ReSaver GUI or CLI write flags in a way that skips a preview. Do not work around a locked save.

Useful context from WingedGuardian toolkit v4.2.0 save docs was used to write this skill (MIT); this kit keeps none of that vault or hook machinery.
