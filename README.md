# Grok Modding Kit for Skyrim (SE / AE / VR)

[![Code: MIT](https://img.shields.io/badge/code-MIT-blue.svg)](LICENSE)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC%20BY%204.0-lightgrey.svg)](LICENSE-docs)

A starter kit for running a **Grok Bot** as a careful Skyrim modding assistant. The bot works from its own Linux box, reaches **your own** Windows modding PC over Tailscale + SSH, diagnoses read-only first, and changes things only through a staged, SHA-256-verified, rollback-ready workflow that you approve.

> **No mods are redistributed here.** This repository contains only original instructions, skills, templates and small wrapper scripts. It ships no plugins, scripts, meshes, textures, archives or third-party binaries. Get mods and tools from their official pages (for mods, the [Nexus Mods](https://www.nexusmods.com/) page of each mod) and respect each author's permissions.

## Install
The kit has two halves: the **Windows modding PC** (where Skyrim runs) and the **bot's Linux box** (where the bot works). Full step-by-step instructions for both games are in **[INSTALL.md](INSTALL.md)**.

**On the Windows PC (Skyrim SE/AE or Skyrim VR):**
1. Download the latest release zip (or Code > Download ZIP) and unzip it anywhere.
2. Double-click **`install.bat`**. Optional: run `install.bat -DryRun` first from a Command Prompt to preview.
3. Pick **1 = Skyrim SE/AE** or **2 = Skyrim VR**, approve the Windows admin prompt, and answer each question. Enter always means No.
4. Follow the "Next steps" it prints.

`install.bat` checks prerequisites, then runs `pc-setup\setup.bat`/`setup.ps1`. It offers Python, Git, Tailscale and OpenSSH Server, creates staging and backup folders, checks your game folder and script extender, and adds the bot's **public** SSH key. It backs up any file before changing it. It never edits `modlist.txt`, `plugins.txt`, `loadorder.txt` or any game or mod file.

**On the bot's box (Linux):**
```bash
unzip Grok-Modders-Kit-for-Skyrim.zip -d Grok-Modders-Kit-for-Skyrim && cd Grok-Modders-Kit-for-Skyrim
sha256sum -c SHA256SUMS
bash tools/install.sh --skills-dir <YOUR_SKILLS_FOLDER>
```
Then follow **[QUICKSTART.md](QUICKSTART.md)** or the full **[SETUP.md](SETUP.md)**. Every feature is listed in **[CAPABILITIES.md](CAPABILITIES.md)**.

### SE/AE vs VR at a glance
| | Skyrim SE / AE (flat) | Skyrim VR |
| --- | --- | --- |
| Game exe (Steam folder) | `SkyrimSE.exe` (`steamapps\common\Skyrim Special Edition`) | `SkyrimVR.exe` (`steamapps\common\SkyrimVR`) |
| Script extender | SKSE64 (`skse64_loader.exe`), build must match 1.5.97 or 1.6.x | SKSEVR (`sksevr_loader.exe`) |
| Address Library | Address Library for SKSE Plugins | VR Address Library for SKSEVR |
| My Games / INIs | `Documents\My Games\Skyrim Special Edition` | `Documents\My Games\Skyrim VR` |
| xEdit | SSEEdit | TES5VREdit (`-tes5vr`) |
| Light plugins (ESL) | Native | Needs the "Skyrim VR ESL Support" SKSEVR plugin |

More detail, including GOG and uninstall, is in [INSTALL.md](INSTALL.md).

## What's inside
| Path | What |
| --- | --- |
| [`install.bat`](install.bat) / [`INSTALL.md`](INSTALL.md) | Windows installer for the modding PC (asks SE/AE or VR) and its step-by-step instructions |
| [`QUICKSTART.md`](QUICKSTART.md) / [`SETUP.md`](SETUP.md) | Short path / full step-by-step setup for a new user |
| [`CAPABILITIES.md`](CAPABILITIES.md) | One line per tool, skill, doc and template |
| [`docs/`](docs/) | Workflow and safety rules, installer runbook, remote session, DevBench API, optional CLIs, Creation Kit for VR |
| [`pc-setup/`](pc-setup/) | Windows `setup.bat` + `setup.ps1` for the gaming PC: Python, Git, Tailscale, OpenSSH Server, folders, SE/AE or VR game check, bot public key, read-only path detection |
| [`tools/`](tools/) | Box tools: `logsum`, `tomd`, `chunk`, `digest-watch`, `boxkit`, `devbench`, `psenc`, `socks5nc`, optional CLI wrappers; `install.sh`, `env.sh`, hash-pinned `requirements.txt` |
| [`skills/`](skills/) | Five Grok Bot skills (`SKILL.md` each) |
| [`templates/`](templates/) | `LOCATIONS.example.md`, `CHANGES.template.md`, `SHA256SUMS-HOWTO.md`, `rollback.template.ps1`, `papyrus.toml`, bot-roster role cards |
| [`LICENSE`](LICENSE) / [`LICENSE-docs`](LICENSE-docs) / [`LICENSE-NOTES.md`](LICENSE-NOTES.md) | MIT for code, CC BY 4.0 for docs; third-party license notes |
| `SHA256SUMS` | Per-file checksums |

## Requirements
- A Grok Bot with its own Linux box and Python 3.11+.
- Your own Windows 10 or 11 PC with Skyrim SE/AE or Skyrim VR, **Mod Organizer 2** (recommended) and the matching script extender (SKSE64 or SKSEVR).
- Tailscale on both machines (free tier is fine) and OpenSSH Server on the PC.
- For `logsum`: the **rtk oss 1.2.0** binary (Apache-2.0; not `rtk-proxy`).
- Optional: DevBench + DevBench GFx (live in-game testing), houseCARL (record work), the Skyrim AI Assistant toolkit by WingedGuardian, and the CLIs in [`docs/OPTIONAL-CLIS.md`](docs/OPTIONAL-CLIS.md).

## Safety model (short)
1. Read-only first. One ranked fix list, one approval.
2. Exactly one bot (the Installer) ever writes to the PC.
3. Nothing deploys without the owner's own "go".
4. Stage on the box, SHA-256 every file, back up live files, ship a rollback script ([`docs/INSTALLER-RUNBOOK.md`](docs/INSTALLER-RUNBOOK.md)).
5. Never hand-edit `plugins.txt`, `loadorder.txt` or `modlist.txt`; never write into `Data/` directly; never write while the game or MO2 is open.

Full rules: [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

## Contributing
Issues and pull requests are welcome. Please:
- keep everything **generic and SFW**: no personal host names, IPs, usernames, paths, emails or API keys, and no mod assets;
- use `<PLACEHOLDERS>` for anything machine-specific;
- keep tools read-side by default, with any write behind an explicit flag;
- pin new Python dependencies with hashes (`pip-compile --generate-hashes`) and update `SHA256SUMS` (`find . -type f ! -name SHA256SUMS ! -path './.git/*' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS`).

**Security:** never paste passwords, private keys or tokens into an issue, a chat or a kit file. The bot only ever needs your **public** SSH key.

## License
Code (`install.bat`, `tools/`, `pc-setup/`, `templates/rollback.template.ps1`): [MIT](LICENSE). Docs, skills and templates: [CC BY 4.0](LICENSE-docs). Copyright (c) 2026 Jezebel Graves. Third-party tools keep their own licenses; see [`LICENSE-NOTES.md`](LICENSE-NOTES.md).
