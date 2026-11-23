---
name: skyrim-nif
description: >-
  Inspect or carefully edit Skyrim NIF meshes. Use for texture paths, shader
  issues, VR-critical skeleton nodes, or geometry problems.
---
# NIF meshes

Read first (`list-textures`, `list-strings`, `shader-info`, or NifSkope). Ask before any write. Stage a copy, SHA-256, back up the live file, and re-hash after. Only the Installer bot writes to the PC. Never write into `Data/` directly.

## VR-critical
- **PreWEAPON and PreSHIELD skeleton nodes can CTD in VR.** The engine does a text-contains search for WEAPON/SHIELD and can match the `Pre` prefix. Check node names and rename or remove the prefix only with the owner's go.
- Custom-skeleton VR users often need the XP32 first-person skeleton CTD bugfix (install through the mod manager).

## Tooling notes
This kit does not bundle AutoMod, PyFFI scripts, or Blender add-ons. If those tools are already on the box or PC, use them read-only first. PyFFI cannot read SSE `BSTriShape` and must not be used to author animation controllers (the file can look valid and still CTD the game). Prefer a second parser (PyNifly or NifSkope) before in-game testing, especially in the headset.

A successful parse is not a visual confirmation. Ask the owner to look at the result in game or in NifSkope.

Facts above include VR-critical notes from WingedGuardian toolkit v4.2.0 skill docs (MIT, not bundled as tools).
