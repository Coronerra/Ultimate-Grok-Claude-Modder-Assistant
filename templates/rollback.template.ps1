# rollback.ps1 template (Grok modding kit). Copy into a package folder and fill in the CONFIG block.
# Run on the modding PC with Skyrim AND Mod Organizer 2 closed. Installer bot only, after the owner's go.
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Mode Backup
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Mode Deploy  -Stage <STAGING_DIR>\<package>
#   powershell -ExecutionPolicy Bypass -File rollback.ps1 -Mode Restore [-BackupDir <BACKUP_DIR>\<package>-yyyyMMdd-HHmmss]
# Never edits plugins.txt, loadorder.txt, modlist.txt or any mod not listed below.
param(
  [ValidateSet('Backup','Deploy','Restore')][string]$Mode = 'Backup',
  [string]$Stage = '',
  [string]$BackupDir = ''
)
$ErrorActionPreference = 'Stop'

# ---------------- CONFIG ----------------
$Package   = '<package-name>'
$ModDir    = '<MO2_INSTANCE>\mods\<ModFolder>'      # the ONE mod folder this package writes to
$BackupRoot= '<BACKUP_DIR>'                          # e.g. C:\Modding\Backups
$GameProcs = '^(SkyrimVR|SkyrimSE|Skyrim|ModOrganizer|CreationKit)$'
# Files relative to $ModDir. Pre = live hash before the change ('' = file is new, must not exist).
# New = staged hash (must match SHA256SUMS).
$Files = [ordered]@{
  'Scripts\<Name>.pex'        = @{ Pre = '<SHA256_UPPER>'; New = '<SHA256_UPPER>' }
  'Source\Scripts\<Name>.psc' = @{ Pre = '<SHA256_UPPER>'; New = '<SHA256_UPPER>' }
}
# ----------------------------------------

function Get-Sha($p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash }
if (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $GameProcs }) {
  throw 'Close Skyrim, Mod Organizer 2 and the Creation Kit first.'
}
if (!(Test-Path -LiteralPath $ModDir)) { throw "Mod folder not found: $ModDir" }

function Latest-Backup {
  $b = Get-ChildItem -LiteralPath $BackupRoot -Directory -Filter "$Package-*" -ErrorAction SilentlyContinue |
       Sort-Object Name -Descending | Select-Object -First 1
  if (!$b) { throw "No backup found under $BackupRoot for $Package. Run -Mode Backup first." }
  return $b.FullName
}

function Do-Backup {
  $d = Join-Path $BackupRoot ("$Package-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  $manifest = @()
  foreach ($f in $Files.Keys) {
    $src = Join-Path $ModDir $f
    $pre = $Files[$f].Pre
    if ($pre -eq '') {
      if (Test-Path -LiteralPath $src) { throw "Expected new file already exists: $f. Stop and re-stage." }
      $manifest += "NEW  $f"; continue
    }
    if (!(Test-Path -LiteralPath $src)) { throw "Missing live file: $src" }
    $h = Get-Sha $src
    if ($h -ne $pre) { throw "Live file changed since staging (expected $pre, got $h): $f. Stop and re-stage." }
    $dst = Join-Path $d $f
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
    if ((Get-Sha $dst) -ne $h) { throw "Backup copy hash mismatch: $f" }
    $manifest += "$h  $f"
  }
  $manifest | Set-Content -LiteralPath (Join-Path $d 'BACKUP-MANIFEST.txt')
  "Backup OK: $d"
}

function Do-Deploy {
  if ($Stage -eq '') { throw 'Pass -Stage <STAGING_DIR>\<package>' }
  $src = Join-Path $Stage 'stage\<ModFolder>'
  $null = Latest-Backup   # refuse without a backup
  foreach ($f in $Files.Keys) {
    $s = Join-Path $src $f
    if (!(Test-Path -LiteralPath $s)) { throw "Staged file missing: $s" }
    if ((Get-Sha $s) -ne $Files[$f].New) { throw "Staged file hash mismatch (check SHA256SUMS): $f" }
    $live = Join-Path $ModDir $f
    $pre = $Files[$f].Pre
    if ($pre -ne '' -and (Get-Sha $live) -ne $pre) { throw "Live file changed since backup: $f" }
  }
  foreach ($f in $Files.Keys) {
    $dst = Join-Path $ModDir $f
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Copy-Item -LiteralPath (Join-Path $src $f) -Destination $dst -Force
    if ((Get-Sha $dst) -ne $Files[$f].New) { throw "Post-deploy hash mismatch: $f (run -Mode Restore)" }
  }
  "Deploy OK. Plugins/load order untouched; enable anything new in MO2 yourself."
}

function Do-Restore {
  $d = if ($BackupDir -ne '') { $BackupDir } else { Latest-Backup }
  $man = Get-Content -LiteralPath (Join-Path $d 'BACKUP-MANIFEST.txt')
  foreach ($line in $man) {
    if ($line -match '^NEW\s+(.+)$') {
      $p = Join-Path $ModDir $Matches[1]
      if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }   # added by this package
      continue
    }
    if ($line -match '^([0-9A-F]{64})\s+(.+)$') {
      $h = $Matches[1]; $f = $Matches[2]
      $dst = Join-Path $ModDir $f
      Copy-Item -LiteralPath (Join-Path $d $f) -Destination $dst -Force
      if ((Get-Sha $dst) -ne $h) { throw "Restore hash mismatch: $f" }
    }
  }
  "Restore OK from $d"
}

switch ($Mode) { 'Backup' { Do-Backup } 'Deploy' { Do-Deploy } 'Restore' { Do-Restore } }
