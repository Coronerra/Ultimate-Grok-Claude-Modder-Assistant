# Installing the Grok Modding Kit for Skyrim (SE/AE and VR)

The kit works with **Skyrim Special Edition / Anniversary Edition** (flat screen) and **Skyrim VR**. It has two halves:

- **Your Windows modding PC**, where the game runs. `install.bat` sets it up so your bot can reach it.
- **The bot's Linux box**, where the bot works. `tools/install.sh` sets up its tools and skills.

Nothing in this kit is a mod, and nothing it installs goes into your game or mod folders.

---

## Requirements

**On the PC**
- Windows 10 or 11 with Windows PowerShell (built in) and an administrator account you can approve.
- Skyrim SE/AE (Steam or GOG) or Skyrim VR (Steam), started at least once.
- Mod Organizer 2 is recommended. Vortex works, but the docs assume MO2.
- The script extender for your game, installed through your mod manager:
  - SE/AE: **SKSE64**, the build that matches your game version (https://skse.silverlock.org/), plus **Address Library for SKSE Plugins** (https://www.nexusmods.com/skyrimspecialedition/mods/32444).
  - VR: **SKSEVR** (https://skse.silverlock.org/), plus **VR Address Library for SKSEVR** when a mod lists it as a requirement (https://www.nexusmods.com/skyrimspecialedition/mods/58101).
- `winget` (App Installer) is optional. Without it, the installer shows download links for Python, Git and Tailscale instead of installing them.
- A free Tailscale account.

**On the bot's box**
- Linux with Python 3.11 or newer, `bash`, `unzip` and `sha256sum`.

---

## Part 1: the Windows PC

1. **Download** the latest release zip from https://github.com/JezebelGraves/Grok-Modders-Kit-for-Skyrim/releases (or Code > Download ZIP).
2. **Unzip the whole kit** to any folder, for example `%USERPROFILE%\Downloads\Grok-Modders-Kit-for-Skyrim`. Keep the folder structure: `install.bat` needs the `pc-setup` folder next to it. If Windows marks the files as downloaded from the internet, right-click the zip > Properties > Unblock before unzipping.
3. **Optional preview:** open a Command Prompt in that folder and run `install.bat -DryRun`. It walks through every question and changes nothing.
4. **Double-click `install.bat`.** It:
   1. checks prerequisites (Windows, PowerShell, the kit files, winget), and warns if the game or MO2 is running;
   2. asks **which game**: type `1` for Skyrim SE/AE or `2` for Skyrim VR (or start it as `install.bat SE` / `install.bat VR`);
   3. starts the guided setup, which asks Windows for administrator permission.
5. **Answer each question in the setup window.** Every change is asked first, and pressing Enter means **No**. The steps are:
   1. Python 3, Git and Tailscale: installed with winget if you say yes.
   2. OpenSSH Server: the Windows feature, the `sshd` service and a firewall rule for port 22, optionally limited to Tailscale addresses.
   3. Folders: a root folder (default `%USERPROFILE%\GrokModding`) with `Toolkit`, `Staging` and `Backups`.
   4. Game check for the edition you picked: finds the game folder, reads the exe version, checks for `skse64_loader.exe` or `sksevr_loader.exe`, and offers to save these facts to `game-profile.txt` in the root folder.
   5. The bot's **public** SSH key: paste the one line, or the path to its `.pub` file. Private keys are refused.
   6. A read-only summary: Tailscale IP, sshd status, your Windows user name and the game and MO2 paths it found.
6. **Sign in to Tailscale** on the PC if it asks, using the same account as the bot's box.
7. **Follow the "Next steps"** that `install.bat` prints, then press a key to close it.

Everything is logged to `pc-setup\setup-log.txt`. The log never contains key contents, only the key fingerprint.

### What the installer will never do
- Edit `modlist.txt`, `plugins.txt`, `loadorder.txt` or any game or mod file.
- Change a file without backing it up first. `authorized_keys` and `game-profile.txt` are copied to `<file>.bak-<timestamp>` before any change.
- Change your system-wide PowerShell execution policy. The bypass applies only to the one setup process.
- Ask for or store a password.

---

## Part 2: the bot's box

```bash
unzip Grok-Modders-Kit-for-Skyrim.zip -d Grok-Modders-Kit-for-Skyrim
cd Grok-Modders-Kit-for-Skyrim
sha256sum -c SHA256SUMS
bash tools/install.sh --skills-dir <YOUR_SKILLS_FOLDER>
source tools/env.sh
```

Then set up box-side Tailscale and SSH as in [SETUP.md](SETUP.md) Part A, and register the skills (Part C). Tell the bot which game you use (SE/AE or VR), your PC's Tailscale name, your Windows user name, and the paths from the summary. Then say: **"Run the getting-started Skyrim modding skill."**

---

## Skyrim SE/AE vs Skyrim VR

| | Skyrim SE / AE (flat) | Skyrim VR |
| --- | --- | --- |
| Steam game folder | `steamapps\common\Skyrim Special Edition` | `steamapps\common\SkyrimVR` |
| Game exe | `SkyrimSE.exe` | `SkyrimVR.exe` |
| Script extender | SKSE64, `skse64_loader.exe`. SE 1.5.97 and AE 1.6.x need different builds. | SKSEVR, `sksevr_loader.exe` |
| Address Library | Address Library for SKSE Plugins | VR Address Library for SKSEVR (a separate mod) |
| SKSE plugin DLLs | SE or AE builds that match your version | VR builds, or plugins that say they support VR |
| INIs and SKSE logs | `Documents\My Games\Skyrim Special Edition` (GOG: `Skyrim Special Edition GOG`) | `Documents\My Games\Skyrim VR` |
| `plugins.txt` outside MO2 | `%LOCALAPPDATA%\Skyrim Special Edition` | `%LOCALAPPDATA%\Skyrim VR` |
| MO2 game type | Skyrim Special Edition | Skyrim VR |
| xEdit | SSEEdit | TES5VREdit (xEdit with `-tes5vr`) |
| Light plugins (ESL) | Native | Need the "Skyrim VR ESL Support" SKSEVR plugin |
| Creation Kit | The SE Creation Kit | No VR Creation Kit. See [docs/CK-VR-SETUP.md](docs/CK-VR-SETUP.md) |

If you play both, run `install.bat` once for each game. Only the game step differs, and the other steps detect that they're already done.

---

## Uninstall

The kit installs nothing into Skyrim, MO2 or your mods. To remove what the PC setup added, undo only the steps you said yes to:

1. **Bot access (do this first):** delete the bot's key line from `C:\ProgramData\ssh\administrators_authorized_keys` (admin account) or `%USERPROFILE%\.ssh\authorized_keys` (standard account), or copy the `.bak-<timestamp>` file back.
2. **OpenSSH Server**, in an administrator PowerShell:
   ```powershell
   Stop-Service sshd; Set-Service sshd -StartupType Disabled
   Remove-NetFirewallRule -Name OpenSSH-Server-In-TCP
   Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
   ```
3. **Folders:** delete `%USERPROFILE%\GrokModding`, or the root you picked. Check `Backups` first, because it may hold the only copy of files the bot replaced.
4. **Python, Git, Tailscale:** Settings > Apps, or `winget uninstall --id Python.Python.3.13` / `Git.Git` / `Tailscale.Tailscale`. Keep them if other programs use them.
5. **The kit folder:** delete it.

On the bot's box: delete the kit folder, remove the `source .../tools/env.sh` line from `~/.bashrc` and `~/.profile`, and remove the copied skills from your skills folder.

---

## Troubleshooting

- **"Administrator permission was not given"**: you said No to the Windows prompt. Run `install.bat` again and choose Yes.
- **No game found**: the setup looks in Steam libraries and the Bethesda and GOG registry keys. Tell the bot your game folder instead.
- **Script extender loader missing**: install SKSE64 or SKSEVR for your game as described above, then run `install.bat` again to re-check.
- **`winget` not found**: install "App Installer" from the Microsoft Store, or use the download links the setup prints.
- The setup scripts have not been run on a real Windows PC by the author's build bot yet. They passed a PowerShell syntax check and a dry test of the game step. Use `install.bat -DryRun` first if you want to see every question.
