# Optional modding CLIs on the box

The kit ships **wrappers only**. Download each tool from its official release, verify the hash, and unpack it under `tools/vendor/` (untracked; or point the env var elsewhere). Use them on **box copies** of files, never on live PC folders.

| Wrapper | Tool (tested version, license) | Official source | Put it at (default) / env var |
| --- | --- | --- | --- |
| `spriggit` | Mutagen Spriggit Linux CLI 0.41.0, GPL-3.0 | https://github.com/Mutagen-Modding/Spriggit/releases | `tools/vendor/spriggit/Spriggit.CLI` / `SPRIGGIT_HOME` (+ .NET 10: `DOTNET_ROOT`) |
| `champollion` | Champollion 1.3.2 (Papyrus decompiler), LGPL-3.0 | https://github.com/Orvid/Champollion/releases | `tools/vendor/champollion/Champollion.exe` / `CHAMPOLLION_EXE` (+ `wine`, `WINEPREFIX`) |
| `dream_archivetool` | DreamWeave dream_archivetool 1.1.0 (BSA/BA2), MIT OR Apache-2.0 | https://github.com/DreamWeave-MP/dream_archivetool/releases | `tools/vendor/dream_archivetool/dream_archivetool` / `DREAM_ARCHIVETOOL` |
| `tools/extras/inspect_plugin.py` | bethkit (Python plugin reader) | install yourself after review | kit venv |
| (none) | Caprica (Papyrus compiler, Windows exe under Wine), MIT | https://github.com/Orvid/Caprica/releases | your choice; see `templates/papyrus.toml` |
| (none) | papyrus-tools 0.16.x (`papyrus check`), Apache-2.0 | its GitHub releases | use `templates/papyrus.toml` |

Release digests known at time of writing (re-check against the release page):
- `SpriggitLinuxCLI.zip` 0.41.0: `146bf173ac145b8c00c96a9b84670388dcc8819c482151963821b160b4717b5b`
- `Champollion.v1.3.2.zip`: `ea53054276ac8006ccd3b323286bfbc6e34a454fa419d08da9bd440cbd31b383` (computed; no published digest)
- `dream_archivetool-Linux-X64.zip` 1.1.0: `c6166e20f8f1688dd898f09a7ca498296fbcddde42221c5493166a1d8cab0dcf`

Usage notes:
- **Spriggit:** `serialize` needs `--PackageVersion` whenever `--GameRelease` or `--PackageName` is set: `spriggit serialize --InputPath copy.esp --OutputPath out/ --GameRelease SkyrimVR --PackageName Spriggit.Yaml --PackageVersion 0.41.0`. `SkyrimVR`, `SkyrimSE` are valid releases. `deserialize` **overwrites** its `--OutputPath`.
- **Champollion:** always `-p <scratch dir>`; never into live script folders.
- **dream_archivetool:** prefer `info`, `list`, `verify` (read-only); `extract`/`create`/`add` write.
- **Caprica / papyrus-tools:** compile on the box and stage the `.pex` with its hash; record tool + version in CHANGES.md. Don't run `papyrus fmt` or `--fix` on live sources.

Not wrapped by this kit (use upstream directly if you want them): the PC-side Skyrim AI Assistant toolkit's own tools (see SETUP.md), ReSaver/FallrimTools (Nexus mod 5031, Apache-2.0), xEdit/TES5VREdit (Windows).
