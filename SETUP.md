# Setup (new user)

This walks you through connecting a Grok Bot to **your own** modding PC and installing the kit. Every placeholder in `<ANGLE_BRACKETS>` is something you fill in for your setup. Keep real host names, IPs, usernames and paths in the bot's **memory**, not in shared files.

> Never paste a password, private key, API key or token into chat or into any kit file. The bot only ever needs your **public** SSH key, and it should never ask for a password.

---

## Part A: on the bot's box (Linux)

### A1. Unpack and verify the kit
```bash
mkdir -p ~/grok-modding-kit && cd ~/grok-modding-kit
unzip /path/to/grok-modding-kit.zip -d ..        # or copy the folder here
sha256sum -c SHA256SUMS
```

### A2. Install the box tools
```bash
bash tools/install.sh --skills-dir <YOUR_SKILLS_FOLDER>    # options: --no-shell-rc, --force-skills
source tools/env.sh
sha256sum -c SHA256SUMS        # must still pass after install
```
What this does, in one step:
1. creates `tools/venv` **inside the kit**, installs the hash-pinned packages from `tools/requirements.txt` (`--require-hashes`) and adds `tools/lib` to the venv so `from boxkit import guarded_get` works;
2. adds `source <kit>/tools/env.sh` to `~/.bashrc` and `~/.profile` (skip with `--no-shell-rc`), which puts `tools/bin` on PATH;
3. copies `skills/*` into the folder you chose (existing different copies are backed up to `<name>.bak-<timestamp>`); without `--skills-dir` it asks, or skips when non-interactive (`GROK_SKILLS_DIR` also works);
4. smoke-tests the tools.

It **never edits tracked kit files**: `tomd`, `chunk` and `digest-watch` keep `#!/usr/bin/env python3` and re-run themselves under `tools/venv` (override with `KIT_VENV`), so `SHA256SUMS` keeps verifying. It only creates untracked `tools/venv/`, `tools/cache/` and optionally `tools/bin/rtk` (all in `.gitignore`). Optional third-party CLIs go in `tools/vendor/` (see `docs/OPTIONAL-CLIS.md`).

`logsum` also needs the **rtk oss 1.2.0** binary (Apache-2.0). Download the Linux x64 release from the rtk project's official releases page, then:
```bash
RTK_SRC=/path/to/rtk bash tools/install.sh     # copies to tools/bin/rtk and checks tools/bin/rtk.sha256
```
Alternatives: put `rtk` on `PATH`, or set `RTK=/path/to/rtk`. Never install `rtk-proxy` (BUSL licensed).

Environment variables (all optional):

| Variable | Default | Used by |
| --- | --- | --- |
| `KIT_HOME` | the kit folder (auto-detected) | all tools |
| `KIT_LIB` | `$KIT_HOME/tools/lib` | tomd, chunk, digest-watch (finding boxkit) |
| `KIT_VENV` | `$KIT_HOME/tools/venv` | tomd, chunk, digest-watch (re-exec target) |
| `KIT_CACHE` | `$KIT_HOME/tools/cache` | boxkit HTTP cache, digest-watch state |
| `BOXKIT_CACHE` | `$KIT_CACHE/http.sqlite` | boxkit |
| `BOXKIT_EXPIRE_HOURS` / `BOXKIT_TIMEOUT` / `BOXKIT_USER_AGENT` | 6 / 30 / built-in | boxkit |
| `RTK` | `tools/bin/rtk`, then `PATH` | logsum |
| `KIT_TZ` | system local zone | digest-watch timestamps |

Smoke test (install.sh already runs this):
```bash
logsum --help && tomd --help && chunk --help && digest-watch --help && devbench --help && whats-here --help && psenc --help
"$KIT_HOME/tools/venv/bin/python" -c "from boxkit import guarded_get; print('boxkit ok')"
```

### A3. Tailscale in userspace mode (box side)
Most bot boxes can't create a TUN device, so run Tailscale in userspace mode with a local SOCKS5 proxy:
```bash
# install tailscale per https://tailscale.com/download/linux, then:
tailscaled --tun=userspace-networking --socks5-server=localhost:<SOCKS_PORT> \
  --state=$HOME/.tailscale/tailscaled.state &
tailscale up            # opens a sign-in link; YOU complete the sign-in
tailscale status        # your PC should appear once Part B is done
```
`<SOCKS_PORT>` is any free local port (1055 is the common example in Tailscale's docs). Keep the state file so the box rejoins after a restart.

### A4. SSH key and config
```bash
ssh-keygen -t ed25519 -f ~/.ssh/<KEY_NAME>_ed25519 -N ""   # only if you don't have one
cat ~/.ssh/<KEY_NAME>_ed25519.pub                            # this PUBLIC key goes to the PC
```
Add to `~/.ssh/config`:
```
Host <PC_ALIAS>
  HostName <PC_TAILSCALE_NAME_OR_IP>
  User <WINDOWS_USERNAME>
  IdentityFile ~/.ssh/<KEY_NAME>_ed25519
  StrictHostKeyChecking accept-new
  ProxyCommand <KIT_HOME>/tools/bin/socks5nc localhost:<SOCKS_PORT> %h %p
```
`socks5nc` is a tiny Python SOCKS5 ProxyCommand (use `nc -X 5 -x localhost:<SOCKS_PORT> %h %p` instead if your `nc` supports it).

Test: `ssh <PC_ALIAS> ver` should print the Windows version. "General SOCKS server failure" right after startup usually just means retry in a few seconds.

---

## Part B: on your Windows modding PC

### B0. Guided setup: `install.bat` (recommended)
Unzip the whole kit on the PC (any folder, spaces in the path are fine) and double-click **`install.bat`** in the top folder. It checks prerequisites, asks **SE/AE or VR**, then starts `pc-setup\setup.bat`. Step-by-step instructions for both games are in [`INSTALL.md`](INSTALL.md). To preview without changing anything, open a Command Prompt in the kit folder and run `install.bat -DryRun`. (`pc-setup\setup.bat` on its own still works; it asks for the game inside the script.)

`setup.bat` only asks Windows for admin rights (UAC) and starts `setup.ps1` with `-ExecutionPolicy Bypass` **for that one PowerShell process** (your system policy isn't changed). Every install or change is asked first, and Enter means **No**. Re-running is safe: done steps are detected and skipped. It never touches `modlist.txt`, `plugins.txt`, `loadorder.txt` or any game or mod file. Everything is logged with timestamps to `pc-setup\setup-log.txt` (key contents are never logged, only the key fingerprint).

| Step | What it does | How to undo |
| --- | --- | --- |
| 1. Python 3, Git, Tailscale | Detects each; offers `winget install` (Python.Python.3.13, Git.Git, Tailscale.Tailscale). Without winget it prints the official download page. | `winget uninstall --id <id>` or Settings > Apps |
| 2. OpenSSH Server | Offers `Add-WindowsCapability OpenSSH.Server`, sets `sshd` to Automatic and starts it, makes sure the inbound firewall rule `OpenSSH-Server-In-TCP` (TCP 22) exists and is enabled, and offers to limit it to Tailscale's address range. | `Stop-Service sshd; Set-Service sshd -StartupType Disabled`; `Remove-NetFirewallRule -Name OpenSSH-Server-In-TCP` (or `Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -RemoteAddress Any`); `Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0` |
| 3. Folders | Asks for a root (default `%USERPROFILE%\GrokModding`) and offers to create `Toolkit`, `Staging` (= `<STAGING_DIR>`) and `Backups` (= `<BACKUP_DIR>`). | Delete the folders (check `Backups` first) |
| 4. Game (SE/AE or VR) | Uses the edition you picked (or asks), finds that game's folder, reads the game exe version, checks for the right script extender loader (`skse64_loader.exe` for SE/AE, `sksevr_loader.exe` for VR) and lists the matching My Games / plugins folders. Read-only, except that it offers to save these facts to `game-profile.txt` in the folder root (an existing file is backed up first). Prints official links for the edition-specific requirements. | Delete `game-profile.txt` |
| 5. Bot public key | Paste the key line or a `.pub` path. Only a single `ssh-ed25519` / `ssh-rsa` / `ecdsa-...` public key line is accepted (checked against its own data); anything that looks like a private key is refused. Admin account: `C:\ProgramData\ssh\administrators_authorized_keys`, ACL Administrators + SYSTEM only. Standard account: `%USERPROFILE%\.ssh\authorized_keys`, ACL that user + SYSTEM. Duplicates are skipped; the file is backed up to `<file>.bak-<timestamp>` before any change. | Copy the `.bak-<timestamp>` file back, or delete the key's line |
| 6. Summary (read-only) | Tailscale IP (`tailscale ip -4`), sshd status, an `ssh <WINDOWS_USERNAME>@<TAILSCALE_IP> ver` test line, the chosen edition and its game folder, and MO2 (global instances, common folders). | nothing to undo |

Admin vs standard: if you approve UAC with your own account, you're an admin and the admin key file is used. If someone else's admin credentials were needed, the key goes to your own profile.

Not tested on a real Windows PC yet; read the script before running it. Manual steps below do the same by hand.

### B1. Manual steps

1. **Tailscale:** install from https://tailscale.com/download/windows and sign in to the **same tailnet**. Note the machine name shown by `tailscale status`.
2. **OpenSSH Server:** Settings > System > Optional features > add "OpenSSH Server", then in an admin PowerShell:
   ```powershell
   Start-Service sshd; Set-Service -Name sshd -StartupType Automatic
   ```
3. **Authorize the bot's public key.** For a standard user, append it to `%USERPROFILE%\.ssh\authorized_keys`. For an admin account Windows uses `C:\ProgramData\ssh\administrators_authorized_keys` (with restricted ACLs, see Microsoft's OpenSSH docs). `install.bat` can do this step for you.
4. **Git Bash** (from Git for Windows) if you use `.sh` tools on the PC.
5. **Folders the workflow uses** (pick your own and save them in the bot's memory):
   - `<MO2_INSTANCE>`: the MO2 instance folder (contains `ModOrganizer.ini`, `mods\`, `profiles\`)
   - `<STAGING_DIR>`: e.g. `C:\Modding\Staging` (packages land here before deploy)
   - `<BACKUP_DIR>`: e.g. `C:\Modding\Backups` (timestamped backups)
   Keep the game outside `Program Files`.
6. **Optional extra tooling:** the Skyrim AI Assistant toolkit (https://github.com/WingedGuardian/skyrim-ai-assistant-toolkit, MIT, by WingedGuardian) has more analysis tools; the skills mention some of them by name. It is not bundled and the kit's installer does not download it. Follow its own README if you want it.

---

## Part C: import the skills into your bot

`install.sh --skills-dir DIR` already copied them to `DIR/<name>/`. Each folder is one skill with a `SKILL.md` (front matter `name` + `description`, then instructions). Point your bot's skills/workflows folder at `DIR`, or add them as saved skills/workflows in your Grok Bot (or paste the file and ask the bot to save it as a skill). Suggested order:

1. `box-token-saving-tools` (tells the bot to use the tools from Part A)
2. `getting-started-skyrim-modding` (first session)
3. `remote-skyrim-modding-session` (every later session)
4. `housecarl-data-layer-modding` (only if you install houseCARL)
5. `devbench-gfx-menu-testing` (only if you install DevBench + DevBench GFx)
6. `skyrim-whats-here` (only if you install DevBench; optional ToolkitProbe adds gaze and bounds)
7. `triage-and-conflicts`, `skyrim-save`, `skyrim-nif`, `skyrim-audio`, `skyrim-bsa` as needed
8. `delegate-to-claude-code` (with Claude Code as the engineer: `docs/CLAUDE-CODE-ENGINEER.md`)
9. `modding-tech-support` (crash and log diagnosis for your own game; works best with Claude Code)

Before anything else, have the bot read and save `TEAM-RULES.md` as standing instructions (add your own limits at the bottom first, if you have any), then `WHY-GROK-PLUS-CLAUDE.md`.

Then tell the bot what to remember: your PC alias, game edition(s), MO2 instance path, profile name, `<STAGING_DIR>`, `<BACKUP_DIR>`, and which bot is the Installer (see `templates/bot-roster/`).

---

## Part D: DevBench (optional, live in-game testing)

DevBench (by alandtse, GPL-3.0 with modding/linking exceptions) is a dev-only SKSE plugin that exposes inspect / console / Papyrus calls over local HTTP while the game runs. Get it from its official page (Nexus: https://www.nexusmods.com/skyrimspecialedition/mods/181326, source: https://github.com/alandtse/devbench) and install it **through MO2** like any mod.

1. Launch the game through SKSE in MO2 and load a save.
2. On the PC, expose the port to your tailnet only, and only when you choose to:
   ```powershell
   tailscale serve --bg --tcp <DEVBENCH_PORT> tcp://127.0.0.1:<DEVBENCH_PORT>
   ```
   `<DEVBENCH_PORT>` is the port in your DevBench config (SE/AE and VR builds have different defaults).
3. The bot probes `http://<PC_TAILSCALE_IP>:<DEVBENCH_PORT>/api/health` through the SOCKS proxy.
4. Turn it off afterward: `tailscale serve --tcp <DEVBENCH_PORT> off` (or `tailscale serve reset`).

Endpoint examples (inspect, console with `capture:true`, Papyrus call) and the `devbench` client: `docs/DEVBENCH-API.md`. Every-session connection routine: `docs/REMOTE-SESSION.md`.

DevBench GFx (separate SKSE DLL that adds a `gfx` tool for Scaleform menus) is only needed for the `devbench-gfx-menu-testing` skill.

Once DevBench is running, the bot can use `whats-here` (`look`, `near`, `effects`, `watch`) from the box with the same `DEVBENCH_URL` / `DEVBENCH_SOCKS` as `devbench`. See `docs/whats-here.md`.

Optional companions, offered once, never installed by the bot into `Data/`:

| Companion | What it adds |
| --- | --- |
| DevBench (Nexus 181326) | Live state, console and Papyrus in the running game. ToolkitProbe needs **1.35+**. |
| ToolkitProbe (upstream toolkit release zip; not in this kit) | Gaze/hand ray, bounds, textures and a timed watch for `whats-here`. Live-tested on VR; SE/AE experimental. The owner installs it through MO2. See `docs/TOOLKIT-PROBE.md`. |
| What Am I Looking At (Nexus 199906, SE/AE only) | Crosshair pick file that `whats-here look` will attach if present. |

Each is optional and is another SKSE plugin in the load order. The owner installs them with their mod manager.

---

## Part E: first session

Say: **"Run the getting-started Skyrim modding skill."** Then read `docs/WORKFLOW.md` and `docs/INSTALLER-RUNBOOK.md` before approving the first change.
