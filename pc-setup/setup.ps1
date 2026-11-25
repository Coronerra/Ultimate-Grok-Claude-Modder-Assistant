<#
.SYNOPSIS
    Grok Modding Kit - Windows PC-side setup (the gaming / modding PC).

.DESCRIPTION
    Sets up what the kit's docs and skills expect on the modding PC:
      1. Python 3, Git for Windows, Tailscale  (winget if available, else official URL)
      2. OpenSSH Server: capability, sshd service (Automatic, running), firewall rule for TCP 22
      3. A toolkit folder, a staging folder and a backups folder under a root you choose
      4. Game edition (Skyrim SE/AE or Skyrim VR): finds the game folder, checks the matching
         script extender loader, and offers to save the facts to game-profile.txt (backed up first)
      5. The bot's PUBLIC SSH key in the right authorized_keys file, with locked-down ACLs.
         From an administrator account this would give the bot full admin SSH access, so it
         warns and needs ADMIN typed to continue; a separate standard account is recommended.
      6. A read-only summary: Tailscale IP, sshd status, ssh test command, detected MO2 / Skyrim paths

    Every install or change asks first and defaults to No. Safe to re-run: anything already
    done is detected and skipped. Never touches modlist.txt, plugins.txt, loadorder.txt or any
    game or mod file. Logs to setup-log.txt next to this script (key contents are never logged).

    Normally started by setup.bat, which asks Windows for admin rights (UAC).

.PARAMETER Game
    SE (Skyrim Special Edition / Anniversary Edition, flat) or VR (Skyrim VR). Ask (default) prompts.
    install.bat passes the answer it asked for.

.PARAMETER DryRun
    Show what would be done; change nothing. -WhatIf does the same.

.PARAMETER TargetUser
    Windows account the key is for (setup.bat passes the user who started it).

.PARAMETER TargetDomain
    Domain or computer name of TargetUser (setup.bat passes it).

.PARAMETER TargetProfile
    Profile folder of TargetUser (setup.bat passes it).

.PARAMETER PauseAtEnd
    Wait for Enter before closing (setup.bat sets this so the window stays open).

.NOTES
    MIT License. Copyright (c) 2026 Jezebel Graves. See LICENSE in the kit.
    Not tested on real Windows by the kit author's build bot; review before running.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
    Justification = 'Interactive console setup script; coloured prompts are the UI.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '',
    Justification = 'Target* parameters are read by the step functions in script scope.')]
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('SE', 'VR', 'Ask')]
    [string]$Game = 'Ask',
    [switch]$DryRun,
    [string]$TargetUser = $env:USERNAME,
    [string]$TargetDomain = $env:USERDOMAIN,
    [string]$TargetProfile = $env:USERPROFILE,
    [switch]$PauseAtEnd
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
if ($WhatIfPreference) { $DryRun = [switch]$true }

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LogFile = Join-Path $ScriptDir 'setup-log.txt'
$TailscaleCgnat = '100.64.0.0/10'   # Tailscale's documented address range (shared CGNAT block), not a personal IP
$Summary = New-Object System.Collections.Generic.List[string]

# ---------------------------------------------------------------- helpers
function Write-SetupLog {
    param([Parameter(Mandatory = $true)][string]$Message, [string]$Level = 'INFO')
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch { Write-Verbose "log write failed: $_" }
    switch ($Level) {
        'WARN'  { Write-Host $Message -ForegroundColor Yellow }
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        'OK'    { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}

function Read-YesNo {
    # Default is always No. Only y / yes counts as Yes.
    param([Parameter(Mandatory = $true)][string]$Question)
    $answer = Read-Host ("{0} [y/N]" -f $Question)
    $yes = ($answer -match '^\s*(y|yes)\s*$')
    Write-SetupLog ("Asked: {0} -> {1}" -f $Question, $(if ($yes) { 'yes' } else { 'no' }))
    return $yes
}

function Invoke-Change {
    # Runs a change only if the user says yes, and never in dry-run mode.
    param(
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )
    if (-not (Read-YesNo $Description)) { Write-SetupLog "Skipped: $Description"; return $false }
    if ($DryRun) { Write-SetupLog "DRY RUN, not done: $Description" 'WARN'; return $false }
    try {
        & $Action
        Write-SetupLog "Done: $Description" 'OK'
        return $true
    } catch {
        Write-SetupLog ("Failed: {0}: {1}" -f $Description, $_.Exception.Message) 'ERROR'
        return $false
    }
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Sync-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = ($machine, $user | Where-Object { $_ }) -join ';'
}

function Test-Winget { return [bool](Get-Command winget -ErrorAction SilentlyContinue) }

function Install-WithWinget {
    param([string]$Name, [string]$WingetId, [string]$Url)
    if (Test-Winget) {
        Invoke-Change "Install $Name with winget (id $WingetId)?" {
            & winget install --id $WingetId -e --source winget --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) { throw "winget exit code $LASTEXITCODE" }
            Sync-SessionPath
        } | Out-Null
    } else {
        Write-SetupLog "winget is not available. Download $Name from the official page and install it yourself: $Url" 'WARN'
    }
}

# ---------------------------------------------------------------- 1. prerequisites
function Test-Python {
    foreach ($cmd in @('py', 'python')) {
        $c = Get-Command $cmd -ErrorAction SilentlyContinue
        if (-not $c) { continue }
        if ($c.Source -like '*\WindowsApps\*') { continue }   # Microsoft Store alias stub, not a real install
        try {
            $v = if ($cmd -eq 'py') { & py -3 --version 2>&1 } else { & python --version 2>&1 }
            if ("$v" -match 'Python 3\.') { return "$v" }
        } catch { Write-Verbose "python probe failed: $_" }
    }
    return $null
}

function Step-Prerequisite {
    Write-Host ''
    Write-Host '== Step 1: Python 3, Git, Tailscale ==' -ForegroundColor Cyan
    $py = Test-Python
    if ($py) { Write-SetupLog "Python found: $py" 'OK' }
    else { Install-WithWinget -Name 'Python 3' -WingetId 'Python.Python.3.13' -Url 'https://www.python.org/downloads/windows/' }

    if (Get-Command git -ErrorAction SilentlyContinue) { Write-SetupLog ('Git found: ' + (& git --version)) 'OK' }
    else { Install-WithWinget -Name 'Git for Windows (includes Git Bash)' -WingetId 'Git.Git' -Url 'https://git-scm.com/download/win' }

    if (Get-TailscaleExe) { Write-SetupLog 'Tailscale found.' 'OK' }
    else { Install-WithWinget -Name 'Tailscale' -WingetId 'Tailscale.Tailscale' -Url 'https://tailscale.com/download/windows' }
}

function Get-TailscaleExe {
    $c = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $p = Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
    if (Test-Path -LiteralPath $p) { return $p }
    return $null
}

# ---------------------------------------------------------------- 2. OpenSSH Server
function Step-OpenSsh {
    Write-Host ''
    Write-Host '== Step 2: OpenSSH Server ==' -ForegroundColor Cyan
    $cap = $null
    try { $cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1 } catch {
        Write-SetupLog ("Could not query Windows capabilities: {0}" -f $_.Exception.Message) 'WARN'
    }
    if ($cap -and $cap.State -eq 'Installed') {
        Write-SetupLog 'OpenSSH Server capability is installed.' 'OK'
    } elseif ($cap) {
        Invoke-Change "Install the Windows OpenSSH Server feature ($($cap.Name))?" {
            Add-WindowsCapability -Online -Name $cap.Name | Out-Null
        } | Out-Null
    }

    $svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if (-not $svc) { Write-SetupLog 'sshd service not present (OpenSSH Server not installed).' 'WARN'; return }
    if ($svc.StartType -ne 'Automatic') {
        Invoke-Change 'Set the sshd service to start automatically?' { Set-Service -Name sshd -StartupType Automatic } | Out-Null
    } else { Write-SetupLog 'sshd start type is Automatic.' 'OK' }
    $svc.Refresh()
    if ($svc.Status -ne 'Running') {
        Invoke-Change 'Start the sshd service now?' { Start-Service -Name sshd } | Out-Null
    } else { Write-SetupLog 'sshd is running.' 'OK' }

    $rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
    if (-not $rule) {
        Invoke-Change 'Create an inbound firewall rule allowing TCP port 22 for sshd?' {
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
                -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
        } | Out-Null
        $rule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
    } elseif ("$($rule.Enabled)" -ne 'True') {
        Invoke-Change 'The sshd firewall rule exists but is disabled. Enable it?' {
            Enable-NetFirewallRule -Name 'OpenSSH-Server-In-TCP'
        } | Out-Null
    } else { Write-SetupLog 'Firewall rule for sshd (TCP 22) exists and is enabled.' 'OK' }

    if ($rule) {
        $addr = ($rule | Get-NetFirewallAddressFilter).RemoteAddress
        if ("$addr" -ne $TailscaleCgnat) {
            Invoke-Change "Recommended: allow SSH (port 22) only from Tailscale addresses ($TailscaleCgnat)?" {
                Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -RemoteAddress $TailscaleCgnat
            } | Out-Null
        } else { Write-SetupLog 'sshd firewall rule is limited to Tailscale addresses.' 'OK' }
    }
}

# ---------------------------------------------------------------- 3. folders
function Step-Folder {
    Write-Host ''
    Write-Host '== Step 3: Toolkit, staging and backups folders ==' -ForegroundColor Cyan
    $default = Join-Path $TargetProfile 'GrokModding'
    $root = Read-Host ("Root folder for the kit's PC folders (Enter = {0})" -f $default)
    if ([string]::IsNullOrWhiteSpace($root)) { $root = $default }
    $root = $root.Trim().Trim('"')
    Write-SetupLog "Folder root chosen: $root"
    $folders = [ordered]@{ Toolkit = Join-Path $root 'Toolkit'; Staging = Join-Path $root 'Staging'; Backups = Join-Path $root 'Backups' }
    foreach ($k in $folders.Keys) {
        $p = $folders[$k]
        if (Test-Path -LiteralPath $p -PathType Container) { Write-SetupLog "$k folder exists: $p" 'OK'; continue }
        Invoke-Change "Create the $k folder at '$p'?" { New-Item -ItemType Directory -Path $p -Force | Out-Null } | Out-Null
    }
    $Summary.Add("Toolkit folder : $($folders.Toolkit)")
    $Summary.Add("Staging folder : $($folders.Staging)   (<STAGING_DIR> in the docs)")
    $Summary.Add("Backups folder : $($folders.Backups)   (<BACKUP_DIR> in the docs)")
    return $folders
}

# ---------------------------------------------------------------- 4. game edition (SE/AE or VR)
function Get-GameEdition {
    if ($Game -eq 'SE' -or $Game -eq 'VR') { return $Game }
    Write-Host 'Which game is this PC set up for?'
    Write-Host '  1 = Skyrim Special Edition / Anniversary Edition (flat screen)'
    Write-Host '  2 = Skyrim VR'
    while ($true) {
        $a = Read-Host 'Type 1 or 2'
        if ($a -match '^\s*1\s*$') { return 'SE' }
        if ($a -match '^\s*2\s*$') { return 'VR' }
        Write-Host 'Please type 1 or 2.'
    }
}

function Get-GameInfo {
    # Everything that differs between the two editions, in one place. Paths use the current user's profile.
    param([Parameter(Mandatory = $true)][ValidateSet('SE', 'VR')][string]$Edition)
    # The elevated process can belong to another admin account (over-the-shoulder UAC), so prefer the
    # target user's own profile when it differs. Documents may be redirected (e.g. OneDrive) for the current user only.
    $me = try { [Security.Principal.WindowsIdentity]::GetCurrent().Name } catch { '' }
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $local = $env:LOCALAPPDATA
    if ($me -ine ('{0}\{1}' -f $TargetDomain, $TargetUser) -or [string]::IsNullOrEmpty($docs)) {
        $docs = Join-Path $TargetProfile 'Documents'
        $local = Join-Path $TargetProfile 'AppData\Local'
    }
    if ($Edition -eq 'VR') {
        return [ordered]@{
            Name          = 'Skyrim VR'
            SteamFolder   = 'SkyrimVR'
            Exe           = 'SkyrimVR.exe'
            Loader        = 'sksevr_loader.exe'
            ScriptExt     = 'SKSEVR (https://skse.silverlock.org/)'
            AddressLib    = 'VR Address Library for SKSEVR, when a mod lists it as a requirement (https://www.nexusmods.com/skyrimspecialedition/mods/58101). It is not the SE/AE Address Library.'
            MyGames       = Join-Path $docs 'My Games\Skyrim VR'
            PluginsFolder = Join-Path $local 'Skyrim VR'
            xEdit         = 'TES5VREdit (xEdit started with -tes5vr)'
            Notes         = @(
                'SKSE plugins must be VR builds (or say they support VR). SE/AE-only DLLs can crash VR.',
                'Skyrim VR has no native ESL support: light plugins need the "Skyrim VR ESL Support" SKSEVR plugin.',
                'In MO2, pick the "Skyrim VR" game type for the instance.')
        }
    }
    return [ordered]@{
        Name          = 'Skyrim Special Edition / Anniversary Edition'
        SteamFolder   = 'Skyrim Special Edition'
        Exe           = 'SkyrimSE.exe'
        Loader        = 'skse64_loader.exe'
        ScriptExt     = 'SKSE64, the build that matches your game version (https://skse.silverlock.org/)'
        AddressLib    = 'Address Library for SKSE Plugins, "All in one" or the file for your version (https://www.nexusmods.com/skyrimspecialedition/mods/32444)'
        MyGames       = Join-Path $docs 'My Games\Skyrim Special Edition'
        PluginsFolder = Join-Path $local 'Skyrim Special Edition'
        xEdit         = 'SSEEdit (xEdit)'
        Notes         = @(
            'SE 1.5.97 and AE 1.6.x need different SKSE64 and DLL builds; match them to the game version below.',
            'The GOG edition uses its own SKSE64 GOG build and keeps My Games in "Skyrim Special Edition GOG".',
            'In MO2, pick the "Skyrim Special Edition" game type for the instance.')
    }
}

function Step-Game {
    param($Folders)
    Write-Host ''
    Write-Host '== Step 4: Game edition (Skyrim SE/AE or Skyrim VR) ==' -ForegroundColor Cyan
    $edition = Get-GameEdition
    $info = Get-GameInfo -Edition $edition
    Write-SetupLog "Game edition chosen: $($info.Name)"
    $Summary.Add("Edition        : $($info.Name)")

    $roots = @(Find-SkyrimInstall -Edition $edition)
    if ($roots.Count -eq 0) {
        Write-SetupLog "No $($info.Name) install found in Steam, Bethesda or GOG locations. Tell the bot your game folder." 'WARN'
        $Summary.Add("Game folder    : not found (tell the bot the path)")
    }
    $profileLines = New-Object System.Collections.Generic.List[string]
    $profileLines.Add('# Written by the Grok Modding Kit installer. Read-only facts; safe to delete.')
    $profileLines.Add("edition=$edition")
    $profileLines.Add("edition_name=$($info.Name)")
    foreach ($r in $roots) {
        $exe = Join-Path $r.Path $info.Exe
        $ver = $null
        try { $ver = (Get-Item -LiteralPath $exe).VersionInfo.FileVersion } catch { $ver = $null }
        $loader = Test-Path -LiteralPath (Join-Path $r.Path $info.Loader)
        Write-SetupLog ("Game folder ({0}): {1}  exe version {2}" -f $r.Source, $r.Path, $(if ($ver) { $ver } else { 'unknown' })) 'OK'
        if ($loader) { Write-SetupLog "$($info.Loader) found in the game folder." 'OK' }
        else { Write-SetupLog "$($info.Loader) NOT found in the game folder. Install $($info.ScriptExt)." 'WARN' }
        $Summary.Add(("Game folder    : {0} ({1}), version {2}, {3} {4}" -f $r.Path, $r.Source, $(if ($ver) { $ver } else { 'unknown' }), $info.Loader, $(if ($loader) { 'found' } else { 'MISSING' })))
        $profileLines.Add("game_root=$($r.Path)")
        $profileLines.Add("game_version=$ver")
        $profileLines.Add("script_extender_loader_found=$loader")
    }
    foreach ($pair in @(@('My Games folder', $info.MyGames), @('plugins.txt folder (non-MO2)', $info.PluginsFolder))) {
        $exists = Test-Path -LiteralPath $pair[1]
        Write-SetupLog ("{0}: {1}{2}" -f $pair[0], $pair[1], $(if ($exists) { '' } else { ' (not there yet: start the game once)' }))
    }
    $profileLines.Add("my_games=$($info.MyGames)")
    $profileLines.Add("loader=$($info.Loader)")

    Write-Host ''
    Write-Host "What $($info.Name) needs (install these through your mod manager, from the official pages):"
    Write-Host "  - Script extender : $($info.ScriptExt)"
    Write-Host "  - Address Library : $($info.AddressLib)"
    Write-Host "  - Plugin editor   : $($info.xEdit)"
    foreach ($n in $info.Notes) { Write-Host "  - $n" }
    Write-Host 'This step does not install or change any game or mod file.'

    $root = Split-Path -Parent $Folders.Toolkit
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        Write-SetupLog "Folder root $root does not exist; game-profile.txt not written." 'WARN'
        return
    }
    $file = Join-Path $root 'game-profile.txt'
    Invoke-Change "Save these game facts to '$file' (an existing file is backed up first)?" {
        if (Test-Path -LiteralPath $file) {
            $bak = '{0}.bak-{1}' -f $file, (Get-Date -Format 'yyyyMMdd-HHmmss')
            Copy-Item -LiteralPath $file -Destination $bak
            Write-SetupLog "Backed up $file to $bak"
        }
        [IO.File]::WriteAllLines($file, [string[]]$profileLines, (New-Object Text.UTF8Encoding($false)))
    } | Out-Null
}

# ---------------------------------------------------------------- 5. bot public key
function Get-KeyFingerprint {
    param([string]$Base64Blob)
    $bytes = [Convert]::FromBase64String($Base64Blob)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return 'SHA256:' + ([Convert]::ToBase64String($sha.ComputeHash($bytes))).TrimEnd('=') } finally { $sha.Dispose() }
}

function Test-PublicKeyLine {
    # Returns @{Ok; Type; Blob; Reason}. Accepts one OpenSSH public key line only.
    param([string]$Line)
    $r = @{ Ok = $false; Type = $null; Blob = $null; Reason = '' }
    if ($Line -match 'PRIVATE KEY|BEGIN |PuTTY-User-Key-File') { $r.Reason = 'This looks like a PRIVATE key. Never share it. Paste the .pub file instead.'; return $r }
    $types = 'ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh\.com|sk-ecdsa-sha2-nistp256@openssh\.com'
    if ($Line -notmatch ("^(?<type>{0}) (?<blob>[A-Za-z0-9+/]+={{0,3}})( [^\r\n]*)?$" -f $types)) {
        $r.Reason = 'Not a single OpenSSH public key line (expected: ssh-ed25519 / ssh-rsa / ecdsa-... AAAA... comment).'; return $r
    }
    $type = $Matches['type']; $blob = $Matches['blob']
    try {
        $bytes = [Convert]::FromBase64String($blob)
        $len = ([int]$bytes[0] -shl 24) -bor ([int]$bytes[1] -shl 16) -bor ([int]$bytes[2] -shl 8) -bor [int]$bytes[3]
        $inner = [Text.Encoding]::ASCII.GetString($bytes, 4, $len)
        if ($inner -ne $type) { $r.Reason = 'Key data does not match its type prefix.'; return $r }
    } catch { $r.Reason = 'Key data is not valid base64.'; return $r }
    $r.Ok = $true; $r.Type = $type; $r.Blob = $blob
    return $r
}

function Step-PublicKey {
    Write-Host ''
    Write-Host "== Step 5: The bot's PUBLIC SSH key ==" -ForegroundColor Cyan
    Write-Host 'Paste the bot''s public key (one line starting with ssh-ed25519, ssh-rsa or ecdsa-),'
    Write-Host 'or type the path to its .pub file. Press Enter alone to skip. Never paste a private key or a password.'
    $inputText = Read-Host 'Public key or .pub path'
    if ([string]::IsNullOrWhiteSpace($inputText)) { Write-SetupLog 'Public key step skipped.'; return }
    $inputText = $inputText.Trim().Trim('"')
    if ((Test-Path -LiteralPath $inputText -PathType Leaf -ErrorAction SilentlyContinue)) {
        $lines = @(Get-Content -LiteralPath $inputText | Where-Object { $_.Trim() })
        if ($lines -match 'PRIVATE KEY|PuTTY-User-Key-File') { Write-SetupLog 'That file is a PRIVATE key. Refused. Use the matching .pub file.' 'ERROR'; return }
        if ($lines.Count -ne 1) { Write-SetupLog 'That file does not contain exactly one key line; refused.' 'ERROR'; return }
        $line = $lines[0].Trim()
    } else { $line = $inputText }
    $k = Test-PublicKeyLine $line
    if (-not $k.Ok) { Write-SetupLog ("Key refused: {0}" -f $k.Reason) 'ERROR'; return }
    $fp = Get-KeyFingerprint $k.Blob
    Write-SetupLog ("Valid public key: {0} {1}" -f $k.Type, $fp) 'OK'

    # Same account elevated => that account is an administrator. Different account (over-the-shoulder UAC) => standard user.
    $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $target = '{0}\{1}' -f $TargetDomain, $TargetUser
    $targetIsAdmin = ($me -ieq $target)
    if ($targetIsAdmin) {
        $file = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
        $grants = @('*S-1-5-32-544:F', '*S-1-5-18:F')            # Administrators, SYSTEM
    } else {
        $file = Join-Path $TargetProfile '.ssh\authorized_keys'
        $grants = @("${target}:F", '*S-1-5-18:F')               # that user, SYSTEM
    }
    Write-SetupLog ("Account '{0}' is {1}; key file: {2}" -f $target, $(if ($targetIsAdmin) { 'an administrator' } else { 'a standard user' }), $file)

    if ($targetIsAdmin) {
        # Admin keys go in administrators_authorized_keys: full admin over SSH, valid for EVERY admin account.
        # Require a typed confirmation; Enter (or anything else) skips the step.
        Write-Host ''
        Write-Host 'WARNING: you are running setup from an ADMINISTRATOR account.' -ForegroundColor Yellow
        Write-Host '  Adding the key here gives the bot FULL ADMINISTRATOR access to this PC over SSH,' -ForegroundColor Yellow
        Write-Host '  and the key works for EVERY administrator account on this PC.' -ForegroundColor Yellow
        Write-Host '  Recommended: give the bot its own standard Windows account instead.' -ForegroundColor Yellow
        Write-Host '  See INSTALL.md, "Give the bot its own standard account". Press Enter to skip this step.' -ForegroundColor Yellow
        $confirm = Read-Host 'Type ADMIN (capitals) to give the bot administrator SSH access anyway'
        if ($confirm -cne 'ADMIN') {
            Write-SetupLog 'Admin SSH key skipped. Recommended: a separate standard Windows account for the bot (INSTALL.md).' 'WARN'
            return
        }
        Write-SetupLog 'Owner typed ADMIN: continuing with administrator SSH access for the bot.' 'WARN'
    }

    if (Test-Path -LiteralPath $file) {
        foreach ($l in Get-Content -LiteralPath $file) {
            $parts = $l.Trim() -split '\s+'
            if ($parts.Count -ge 2 -and $parts[1] -eq $k.Blob) { Write-SetupLog "This key is already in $file; nothing to do." 'OK'; Set-KeyFileAcl -File $file -Grants $grants -AskOnly; return }
        }
    }
    Invoke-Change "Add this key ($fp) to '$file' (backing the file up first) and lock its permissions?" {
        $dir = Split-Path -Parent $file
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        if (Test-Path -LiteralPath $file) {
            $bak = '{0}.bak-{1}' -f $file, (Get-Date -Format 'yyyyMMdd-HHmmss')
            Copy-Item -LiteralPath $file -Destination $bak
            Write-SetupLog "Backed up $file to $bak"
            $existing = [IO.File]::ReadAllText($file)
            $prefix = if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) { "`r`n" } else { '' }
        } else { $prefix = '' }
        [IO.File]::AppendAllText($file, $prefix + $line + "`r`n", (New-Object Text.UTF8Encoding($false)))
        Set-KeyFileAcl -File $file -Grants $grants
    } | Out-Null
}

function Set-KeyFileAcl {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$File, [string[]]$Grants, [switch]$AskOnly)
    if ($AskOnly) {
        if (-not (Read-YesNo "Re-apply the locked-down permissions on '$File'?")) { return }
        if ($DryRun) { Write-SetupLog "DRY RUN, not done: icacls on $File" 'WARN'; return }
    }
    if (-not $PSCmdlet.ShouldProcess($File, 'icacls /inheritance:r and grant')) { return }
    $argList = @($File, '/inheritance:r')
    foreach ($g in $Grants) { $argList += @('/grant', $g) }
    & icacls.exe @argList | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "icacls exit code $LASTEXITCODE" }
    Write-SetupLog "Permissions set on $File (inheritance removed; owner-only plus SYSTEM)." 'OK'
}

# ---------------------------------------------------------------- 6. read-only detection + summary
function Get-RegValue {
    param([string]$Path, [string]$Name)
    try { return (Get-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null }
}

function Find-SkyrimInstall {
    # Returns objects with Path and Source for the chosen edition only. Read-only.
    param([Parameter(Mandatory = $true)][ValidateSet('SE', 'VR')][string]$Edition)
    $info = Get-GameInfo -Edition $Edition
    $found = New-Object System.Collections.Generic.List[object]
    $libs = New-Object System.Collections.Generic.List[string]
    foreach ($p in @(
            (Get-RegValue 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' 'InstallPath'),
            (Get-RegValue 'HKCU:\Software\Valve\Steam' 'SteamPath'))) {
        if ($p) { $libs.Add(($p -replace '/', '\')) }
    }
    foreach ($s in @($libs)) {
        $vdf = Join-Path $s 'steamapps\libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $libs.Add(($m.Groups[1].Value -replace '\\\\', '\'))
            }
        }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $dir = Join-Path $lib ("steamapps\common\{0}" -f $info.SteamFolder)
        if (Test-Path -LiteralPath (Join-Path $dir $info.Exe)) { $found.Add([pscustomobject]@{ Path = $dir; Source = 'Steam' }) }
    }
    $bethKey = if ($Edition -eq 'VR') { 'Skyrim VR' } else { 'Skyrim Special Edition' }
    $p = Get-RegValue ("HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\{0}" -f $bethKey) 'Installed Path'
    if ($p -and (Test-Path -LiteralPath (Join-Path $p $info.Exe))) { $found.Add([pscustomobject]@{ Path = $p.TrimEnd('\'); Source = 'registry' }) }
    $gog = 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games'
    if ($Edition -eq 'SE' -and (Test-Path -LiteralPath $gog)) {
        foreach ($k in Get-ChildItem -LiteralPath $gog) {
            $name = Get-RegValue $k.PSPath 'gameName'
            $path = Get-RegValue $k.PSPath 'path'
            if ($name -like '*Skyrim*' -and $path -and (Test-Path -LiteralPath (Join-Path $path $info.Exe))) { $found.Add([pscustomobject]@{ Path = $path.TrimEnd('\'); Source = 'GOG' }) }
        }
    }
    $seen = @{}
    $out = New-Object System.Collections.Generic.List[object]
    foreach ($f in $found) { $key = $f.Path.ToLowerInvariant(); if (-not $seen.ContainsKey($key)) { $seen[$key] = $true; $out.Add($f) } }
    return $out.ToArray()
}

function Find-Mo2 {
    $found = New-Object System.Collections.Generic.List[string]
    $inst = Join-Path $env:LOCALAPPDATA 'ModOrganizer'
    if (Test-Path -LiteralPath $inst) {
        foreach ($d in Get-ChildItem -LiteralPath $inst -Directory) {
            if (Test-Path -LiteralPath (Join-Path $d.FullName 'ModOrganizer.ini')) { $found.Add("MO2 global instance: $($d.FullName)") }
        }
    }
    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($drv in (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' })) {
        foreach ($n in @('MO2', 'ModOrganizer', 'Mod Organizer 2', 'Modding', 'Modding\MO2', 'Games\MO2')) { $candidates.Add((Join-Path $drv.Root $n)) }
    }
    foreach ($n in @('Mod Organizer 2', 'ModOrganizer')) { $candidates.Add((Join-Path $env:ProgramFiles $n)) }
    foreach ($c in $candidates) {
        if (-not (Test-Path -LiteralPath $c -PathType Container)) { continue }
        $exes = @(Get-ChildItem -LiteralPath $c -Filter 'ModOrganizer.exe' -File -Recurse -Depth 2 -ErrorAction SilentlyContinue)
        foreach ($e in $exes) {
            $portable = Test-Path -LiteralPath (Join-Path $e.DirectoryName 'portable.txt')
            $found.Add(('MO2{0}: {1}' -f $(if ($portable) { ' (portable instance)' } else { '' }), $e.DirectoryName))
        }
    }
    return @($found | Select-Object -Unique)
}

function Step-Summary {
    Write-Host ''
    Write-Host '== Summary (read-only) ==' -ForegroundColor Cyan
    $ts = Get-TailscaleExe
    $ip = $null
    if ($ts) {
        try { $ip = (& $ts ip -4 2>$null | Select-Object -First 1) } catch { $ip = $null }
        if (-not $ip) { $Summary.Add('Tailscale IP   : (not signed in yet: open Tailscale and log in, then run "tailscale ip -4")') }
        else { $Summary.Add("Tailscale IP   : $ip") }
    } else { $Summary.Add('Tailscale IP   : (Tailscale not installed)') }
    $svc = Get-Service -Name sshd -ErrorAction SilentlyContinue
    if ($svc) { $Summary.Add(('sshd           : {0}, start type {1}' -f $svc.Status, $svc.StartType)) } else { $Summary.Add('sshd           : not installed') }
    $Summary.Add("Windows user   : $TargetUser")
    $Summary.Add('SSH test (run on the bot''s box): ssh <WINDOWS_USERNAME>@<TAILSCALE_IP> ver')
    foreach ($m in (Find-Mo2)) { $Summary.Add("Mod manager    : $m") }
    if (-not ($Summary | Where-Object { $_ -like 'Mod manager *' })) { $Summary.Add('Mod manager    : no MO2 found in common places (tell the bot the path)') }
    foreach ($s in $Summary) { Write-SetupLog $s }
    Write-Host ''
    Write-Host 'Tell the bot: which game (SE/AE or VR), your Tailscale machine name or IP, your Windows user name, and the MO2 / game paths above.'
    Write-Host 'Never send a password or a private key.'
}

# ---------------------------------------------------------------- main
try {
    Write-SetupLog ('==== setup.ps1 start{0} (PowerShell {1}) ====' -f $(if ($DryRun) { ' [DRY RUN]' } else { '' }), $PSVersionTable.PSVersion)
    if (-not (Test-IsAdmin)) {
        Write-SetupLog 'Not running as administrator. Start setup.bat (it asks Windows for admin rights).' 'ERROR'
        exit 1
    }
    Write-Host 'Grok Modding Kit PC setup. Every change asks first; Enter means No.' -ForegroundColor Cyan
    Write-Host 'This script never touches modlist.txt, plugins.txt, loadorder.txt or any game or mod files.'
    if ($DryRun) { Write-Host 'DRY RUN: nothing will be changed.' -ForegroundColor Yellow }
    Step-Prerequisite
    Step-OpenSsh
    $folders = Step-Folder
    Step-Game -Folders $folders
    Step-PublicKey
    Step-Summary
    Write-SetupLog '==== setup.ps1 finished ===='
} catch {
    Write-SetupLog ("Unexpected error: {0}" -f $_.Exception.Message) 'ERROR'
    exit 1
} finally {
    if ($PauseAtEnd) { Read-Host 'Press Enter to close' | Out-Null }
}
