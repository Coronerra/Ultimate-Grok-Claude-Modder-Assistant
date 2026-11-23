# Remote session: Tailscale + SSH from the box to your modding PC

One-time setup is in `SETUP.md` (Parts A3, A4, B). This page is the **every-session** routine the `remote-skyrim-modding-session` skill follows, plus fixes for common failures. Keep real host names, IPs and usernames in the bot's memory, not in files.

## 1. Bring the tunnel up (box)
```bash
pgrep -x tailscaled >/dev/null || \
  tailscaled --tun=userspace-networking --socks5-server=localhost:<SOCKS_PORT> \
    --state=$HOME/.tailscale/tailscaled.state >/tmp/tailscaled.log 2>&1 &
tailscale status            # the PC should be listed and not "offline"
```

## 2. Test SSH
```bash
ssh <PC_ALIAS> ver          # prints the Windows version
```
`~/.ssh/config` uses `ProxyCommand <KIT_HOME>/tools/bin/socks5nc localhost:<SOCKS_PORT> %h %p`.

| Symptom | Usual fix |
| --- | --- |
| `General SOCKS server failure` | tailscaled just started or the PC is asleep; wait 5-10 s and retry (max 3). |
| PC missing / offline in `tailscale status` | Owner: open Tailscale on the PC and sign in; wake the PC. |
| `Connection refused` | Owner: `Start-Service sshd` in an admin PowerShell. |
| `Permission denied (publickey)` | Public key not in the right file (`administrators_authorized_keys` for admin accounts), or wrong ACLs. |

## 3. Run PowerShell without quoting pain
Encode scripts as UTF-16LE base64 for `-EncodedCommand`:
```bash
psenc --ssh <PC_ALIAS> 'Get-Process | ? Name -match "Skyrim|ModOrganizer" | Select Name,Id'
# prints the ssh command; add --run to execute it (read-only commands, or approved writes)
```

## 4. Pre-launch checks (read-only)
Game exe / SKSE / Address Library versions match; active MO2 profile; `plugins.txt` full vs light counts (stay under 254 full); missing masters; new SKSE, crash and Papyrus logs since last session (pull a copy to the box and run `logsum` before reading). Report only what changed or broke, most important first.

## 5. Ground rules
- Read-only unless this session has the owner's go for a specific change, and then only the Installer bot writes (`docs/WORKFLOW.md`).
- No writes while Skyrim or MO2 is running.
- Copy files box -> PC only into `<STAGING_DIR>` (`scp -r <package> <PC_ALIAS>:"<STAGING_DIR>/"`); deploy only via the package's `rollback.ps1`.
- Save new facts (paths, versions, project status) to the bot's memory at the end.
