# <Package name> (stage only)

Prepared <date, time, time zone>. Box only. Built with <tool + version>, exit <code>. **Nothing installed or changed on the PC yet. Not tested in game.**

Base: live `<ModFolder>\<file>` (psc `<sha256 short>`, pex `<sha256 short>`), confirmed by a read-only hash at <time>.

## One-line summary
<What changes, in one sentence.>

## What this is not
<Scope limits: files/mods/systems this package deliberately does not touch.>

## What changed vs live
| Item | Live | This stage | Why (source / owner request) |
| --- | --- | --- | --- |
| | | | |

Kill switch / config overrides (if any): <e.g. a global or INI value that restores old behavior>.

Diffs: `diffs/<file>.diff`.

## Files
| Staged path (relative to the mod folder) | Pre hash (live) | New hash |
| --- | --- | --- |
| `Scripts\<Name>.pex` | `<sha256>` | `<sha256>` |

Full list: `SHA256SUMS`.

## Install (Installer bot only, after the owner's go)
1. Close Skyrim and MO2.
2. Copy this package to `<STAGING_DIR>\<package>`.
3. `powershell -ExecutionPolicy Bypass -File rollback.ps1 -Mode Backup`
4. `powershell -ExecutionPolicy Bypass -File rollback.ps1 -Mode Deploy -Stage <STAGING_DIR>\<package>`
5. Owner: enable/tick `<plugin or mod>` in MO2 **yourself** if this package adds one. The scripts never edit plugins.txt / loadorder.txt / modlist.txt.

## Rollback
`powershell -ExecutionPolicy Bypass -File rollback.ps1 -Mode Restore -BackupDir <BACKUP_DIR>\<package>-<timestamp>`

## Shared-file effects
<Other scripts/mods that call into changed files, and why they're unaffected.>

## Verify in game
- [ ] <observable check 1>
- [ ] <log line to look for; run `logsum` on Papyrus.0.log>

## Unverified / open questions
- <anything assumed or not tested>

## Status log
| When | Who | What |
| --- | --- | --- |
| <date> | <bot> | Staged |
