# Installer runbook: backup, deploy, re-hash, rollback

The concrete steps the **Installer bot** (the only bot that writes to the PC) runs for one staged package, after the owner says "go" in their own words. Background and rules: `docs/WORKFLOW.md`. Templates: `templates/rollback.template.ps1`, `templates/SHA256SUMS-HOWTO.md`, `templates/CHANGES.template.md`.

## 0. Preconditions
- Package on the box is complete: `CHANGES.md`, `SHA256SUMS`, `rollback.ps1`, `stage/<ModFolder>/`.
- `cd <package> && sha256sum -c SHA256SUMS` passes **on the box**.
- The owner has closed Skyrim and Mod Organizer 2 (the script checks too).

## 1. Copy to staging and re-hash on the PC
```bash
scp -r <package> <PC_ALIAS>:"<STAGING_DIR>/"
```
Then on the PC (via `psenc --ssh <PC_ALIAS> --run -f check.ps1`), run the PowerShell check from `templates/SHA256SUMS-HOWTO.md`. **Any MISMATCH = stop**, re-copy, re-check. Never "fix" a hash by editing SHA256SUMS.

## 2. Snapshot the load-order lists (they must not change)
```powershell
$p = '<MO2_INSTANCE>\profiles\<PROFILE>'
Get-FileHash -Algorithm SHA256 "$p\plugins.txt","$p\loadorder.txt","$p\modlist.txt" |
  Select Hash,Path | Export-Csv '<STAGING_DIR>\<package>\lists-before.csv' -NoTypeInformation
```

## 3. Backup (verifies live "pre" hashes, then hash-verifies the copy)
```powershell
powershell -ExecutionPolicy Bypass -File '<STAGING_DIR>\<package>\rollback.ps1' -Mode Backup
```
If it reports "live file changed since staging": **stop**. Someone changed the live file; the package must be re-staged from a fresh read.

## 4. Deploy (re-verifies staged hashes, copies, re-hashes live)
```powershell
powershell -ExecutionPolicy Bypass -File '<STAGING_DIR>\<package>\rollback.ps1' -Mode Deploy -Stage '<STAGING_DIR>\<package>'
```
Deploy ends with every live file equal to its staged hash, or it throws and tells you which backup to restore.

## 5. Confirm hands-off lists
Re-run step 2 into `lists-after.csv` and compare. They must be identical. The script never edits them; if the package adds a new plugin, CHANGES.md tells the **owner** which box to tick in MO2.

## 6. Report
Tell the owner: backup folder path, files deployed (with short hashes), anything they must do in MO2, and the verify-in-game list from CHANGES.md. Update CHANGES.md "Status log" and the bot's memory.

## 7. Rollback
```powershell
powershell -ExecutionPolicy Bypass -File '<STAGING_DIR>\<package>\rollback.ps1' -Mode Restore            # newest backup
powershell -ExecutionPolicy Bypass -File '<STAGING_DIR>\<package>\rollback.ps1' -Mode Restore -BackupDir '<BACKUP_DIR>\<package>-yyyyMMdd-HHmmss'
```
Restore checks the backup against its manifest, copies it back, removes files the package newly added, and re-verifies. If the owner had ticked a new plugin, they untick it themselves.
