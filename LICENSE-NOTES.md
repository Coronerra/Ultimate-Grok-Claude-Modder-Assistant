# License notes

## This kit
| Part | License | File |
| --- | --- | --- |
| Scripts and tools: `tools/**` (incl. `install.sh`, `env.sh`, `bin/*`, `lib/boxkit.py`, `extras/*`), `install.bat`, `pc-setup/setup.ps1`, `pc-setup/setup.bat` and `templates/rollback.template.ps1` | **MIT** | `LICENSE` |
| Docs, skills and templates: `*.md` at the top level, `docs/**`, `skills/**`, `templates/**` (except the rollback script) | **CC BY 4.0** | `LICENSE-docs` |

Copyright (c) 2026 Jezebel Graves.

## What this kit does NOT include (by design)
- **No game mods or mod files**: no `.esp/.esm/.esl`, `.bsa/.ba2`, meshes, textures, scripts (`.psc/.pex`) or other assets from any mod. Third-party mods are **not redistributed**; link to their official Nexus Mods (or author) pages instead and let users download them.
- **No third-party binaries.** Users download each tool from its official source and the kit verifies pinned hashes where given.
- No game files from Bethesda (the Creation Kit, masters, `Scripts.zip` sources).

## Third-party software the kit references or calls
Licenses checked against each project's own LICENSE file (GitHub license API) or its Nexus permissions page on 2026-11-22. Nothing below is bundled in this kit.

| Project | License | Source URL | Checked | Notes |
| --- | --- | --- | --- | --- |
| DevBench GFx (kautsaralbaa / kxgcayh) | GPL-3.0-or-later (vendored DevBench API files MIT) | https://github.com/kxgcayh/devbench-gfx/blob/main/LICENSE ; https://www.nexusmods.com/skyrimspecialedition/mods/198173 | 2026-11-22 | not redistributed; users download from source. GitHub API reports GPL-3.0; the Nexus author notes say "GPL-3.0-or-later" and that the license, not the Nexus permission toggles, governs reuse. The Nexus page also says it has been merged into DevBench itself, so newer DevBench builds may not need it. |
| Caprica (Orvid) | MIT | https://github.com/Orvid/Caprica/blob/master/LICENSE | 2026-11-22 | not redistributed; users download from source. Canonical repo: Orvid/Caprica (not a fork). |
| Champollion | **LGPL-3.0** (settled; not MIT) | https://github.com/Orvid/Champollion/blob/main/LICENSE | 2026-11-22 | not redistributed; users download from source; kit ships a wrapper only. Canonical: **Orvid/Champollion** (not a fork; hosts the v1.3.2 release the wrapper targets). Forks infomaniac50/Champollion and nikitalita/Champollion are also LGPL-3.0. |
| xEdit / TES5VREdit | MPL-2.0 | https://github.com/TES5Edit/TES5Edit/blob/dev-4.1.6/LICENSE.txt | 2026-11-22 | not redistributed; users download from source. Referenced only. |
| CKPE: Creation Kit Platform Extended (Perchik71) | LGPL-3.0 | https://github.com/Perchik71/Creation-Kit-Platform-Extended/blob/master/LICENSE | 2026-11-22 | not redistributed; users download from source. Referenced in docs/CK-VR-SETUP.md. Nexus page (mod 71371) permissions not re-checked. |
| Root Builder (Kezyma) | **No license stated** (Nexus custom permissions: no re-upload, no modification without permission) | https://www.nexusmods.com/skyrimspecialedition/mods/31720 ; https://github.com/Kezyma/ModOrganizer-Plugins (no LICENSE file; GitHub license API: Not Found) | 2026-11-22 | not redistributed; users download from source. Link to the Nexus page only; never bundle or modify it. **VERIFY** with the author before anything beyond linking. |
| Creation Kit Downgrade Patcher (wSkeever) | CC BY-SA 4.0 (per Nexus author notes) | https://www.nexusmods.com/skyrimspecialedition/mods/190110 | 2026-11-22 | not redistributed; users download from source. Nexus toggles also apply, e.g. "ask before forks / AI modification". No GitHub repo found. Referenced only. |
| papyrus-tools (Kiyozz) | Apache-2.0 | https://github.com/Kiyozz/papyrus-tools/blob/main/LICENSE | 2026-11-22 | not redistributed; users download from source. Kit ships only an original starter `templates/papyrus.toml`. The box copy's LICENSE is also Apache-2.0. |
| bethkit (Modding-Forge; PyPI `bethkit` 2.6.0) | Apache-2.0 | https://github.com/Modding-Forge/bethkit.py/blob/master/LICENSE ; https://pypi.org/project/bethkit/ | 2026-11-22 | not redistributed; users download from source; used only by optional `tools/extras/inspect_plugin.py`. Not pinned in requirements.txt. |
| DevBench (alandtse) | GPL-3.0-or-later WITH Modding Exception AND GPL-3.0 Linking Exception; DevBenchAPI.h/.cpp MIT | https://github.com/alandtse/devbench/blob/main/COPYING ; README "License" section | 2026-11-22 | not redistributed; users download from source. Kit has no DevBench code; `tools/bin/devbench` is an original HTTP client. |
| Spriggit (Mutagen-Modding) | GPL-3.0 | https://github.com/Mutagen-Modding/Spriggit/blob/dev/LICENSE | 2026-11-22 | not redistributed; users download from source; wrapper only. |
| dream_archivetool (DreamWeave-MP) | MIT OR Apache-2.0 (LICENSE-MIT + LICENSE-APACHE; bundled fonts have their own licenses) | https://github.com/DreamWeave-MP/dream_archivetool | 2026-11-22 | not redistributed; users download from source; wrapper only. |
| houseCARL (Avick3110) | GPL-3.0 (GitHub API; "-only" per earlier notes, not re-read) | https://github.com/Avick3110/houseCARL/blob/main/LICENSE | 2026-11-22 | not redistributed; users download from source. |
| Skyrim AI Assistant Toolkit (WingedGuardian) | MIT | https://github.com/WingedGuardian/skyrim-ai-assistant-toolkit/blob/master/LICENSE | 2026-11-22 | Not redistributed. The skills reference its tools by name but contain no copied code. If any substantial part is ever copied, keep its copyright + MIT notice (THIRD-PARTY-NOTICES). |
| rtk oss 1.2.0 | Apache-2.0 (do **not** use rtk-proxy, BUSL) | (prior box notes) | not re-checked | Hash only (`tools/bin/rtk.sha256`). |
| markitdown, chonkie, APScheduler 3.x | MIT | (PyPI metadata, prior notes) | not re-checked | pip-installed by install.sh. |
| requests-cache / pybreaker / requests | BSD-2-Clause / BSD-3-Clause / Apache-2.0 | (PyPI metadata, prior notes) | not re-checked | pip-installed by install.sh. |
| ReSaver / FallrimTools | Apache-2.0 | (prior box notes) | not re-checked | Referenced only. |
| Tailscale client, OpenSSH | BSD-3-Clause; BSD-style | (prior notes) | not re-checked | Users install themselves. |

**Still to verify:** Root Builder (no license stated; custom Nexus permissions). The CKPE and Champollion Nexus pages were not checked; their GitHub licenses are what is recorded.

`tools/bin/socks5nc`, `devbench`, `psenc`, the `spriggit` / `champollion` / `dream_archivetool` wrappers and all other files in this kit are original to the kit (licensed as in the table above). The wrapped tools themselves are not included.

Nexus Mods: also check each mod's own permissions tab before linking to or describing anything beyond a link.
