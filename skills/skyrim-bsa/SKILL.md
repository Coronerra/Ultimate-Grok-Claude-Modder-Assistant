---
name: skyrim-bsa
description: Read, list or (with approval) extract BSA/BA2 archives. Use when checking whether a mesh or texture is in an archive or loose.
---
# BSA / BA2 archives

**Loose files always override BSAs.** Check for a loose file in the relevant folder before assuming the archive is what the game loads.

Read-only first: info, list, validate, or the kit's optional `dream_archivetool` wrapper (`docs/OPTIONAL-CLIS.md`). If a lister defaults to a short page (AutoMod's `archive list` default `--limit` is 100), do not conclude a file is absent until you have asked for the full list (`showing` vs `totalInArchive`, or `--limit 0`).

Ask before extract, create, add, remove or merge. Stage outputs outside the live game folder. Never write into `Data/` directly. Only the Installer bot writes to the PC, after a backup and a re-hash. Never edit `modlist.txt`, `plugins.txt` or `loadorder.txt`.

This kit does not bundle AutoMod or BSArch. The listing-limit and loose-file reminders follow WingedGuardian toolkit v4.2.0 BSA skill docs (MIT).
