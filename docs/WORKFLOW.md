# Workflow: how changes reach the modding PC safely

The kit's whole point is that a bot never "just edits" a live game. Every change follows the same path:

```
read-only scan -> ranked fix list -> owner's "go" -> stage on box -> SHA-256 -> backup live files
 -> deploy (Installer bot only) -> verify hashes -> in-game test -> CHANGES.md updated  (rollback ready at every step)
```

## 1. Roles (see `templates/bot-roster/`)

| Role | Writes to PC? | Job |
| --- | --- | --- |
| **Installer bot** | **Yes, the only one** | Backups, deploys, restores, MO2 mod-folder creation. Runs the rollback script. |
| **Chief of Staff** | No | Routes work, keeps the briefing and roster current, never relays a "go" on the owner's behalf. |
| **Researcher bots** | No (read-only) | Sources, compatibility, versions; label every claim `[cited]`, `[box]` or `[UNCERTAIN]`. |
| **Specialist bots** | No (stage only) | Build a fix on the box (scripts, patches, INIs), write CHANGES.md, SHA256SUMS and rollback.ps1. One named specialist may be the only **plugin (ESP) editor**. |

Rules that hold for every role:

- **Only the owner's own "go", in their own words, authorizes a deploy.** A relay from another bot or a "go" in a research thread does not count.
- **One writer.** If two bots need the same file, the Installer sequences them.
- Read-only means read-only: no "quick fix" by a researcher.

## 2. Hard rules on the PC

1. **Never edit `plugins.txt`, `loadorder.txt` or `modlist.txt`** by hand or with a tool. Enabling, disabling and sorting are the owner's job in the mod manager. A package's notes say exactly which plugin to tick and where; the owner does it.
   - Before and after any CK/xEdit/tool session, hash those files. If they changed, restore the backup and tell the Installer.
   - If something ever must write one (owner-approved), write UTF-8 **without BOM**: `[IO.File]::WriteAllLines(path, lines, (New-Object Text.UTF8Encoding $false))`.
2. **Never write into the game's `Data\` folder directly.** New or changed files go into a new or existing **MO2 mod folder**.
3. **No writes while Skyrim or MO2 is running.** Scripts check for the processes and refuse.
4. **Back up before every edit**, to `<BACKUP_DIR>\<package>-<yyyyMMdd-HHmmss>\`, and verify the backup's hashes.
5. **Never compact FormIDs a save already references, never delete scripted records from a plugin a save uses** ("lobotomize" instead), never clean master files.
6. Don't add or remove script-heavy mods mid-playthrough without the owner understanding the risk.

## 3. Staging (on the box)

Each change is a package folder:

```
<package-name>-<yyyymmdd>/
  CHANGES.md          # from templates/CHANGES.template.md
  SHA256SUMS          # every staged file (see templates/SHA256SUMS-HOWTO.md)
  rollback.ps1        # from templates/rollback.template.ps1 (Backup / Deploy / Restore)
  stage/<ModFolder>/  # exact tree that lands in <MO2_INSTANCE>\mods\<ModFolder>\
  diffs/              # source diffs vs. live, for review
```

- Base every change on a **read-only hash of the live file** taken just before staging. Record it in CHANGES.md as the "pre" hash.
- Compile/build on the box when possible (e.g. Caprica for Papyrus) and record tool + version.
- State plainly what was **not** tested ("not tested in game").

## 4. SHA-256 verification

- On the box: `cd stage && find . -type f -print0 | sort -z | xargs -0 sha256sum > ../SHA256SUMS`.
- After the files reach `<STAGING_DIR>` on the PC, the Installer re-hashes them and compares with SHA256SUMS **before** deploying.
- `rollback.ps1 -Mode Deploy` refuses if (a) the live file no longer matches its recorded "pre" hash (someone changed it; re-stage) or (b) a staged file doesn't match SHA256SUMS.
- After deploy, live files are re-hashed and must equal the staged hashes.

## 5. Backups and rollback

`rollback.ps1` has three modes:

| Mode | Does |
| --- | --- |
| `Backup` | Refuses if game/MO2 is open; checks each live file's pre hash; copies to a timestamped backup folder; verifies the copy's hash; writes a manifest. |
| `Deploy` | Requires a verified backup; verifies staged hashes; copies staged files into the MO2 mod folder; verifies live hashes after copy. |
| `Restore` | Copies the backup back (and removes files that the package added); verifies hashes match the backup manifest. |

It **never** touches `plugins.txt`, `loadorder.txt`, `modlist.txt`, or any mod not listed in the script.

## 6. After deploy

1. Owner enables any new plugin/mod in MO2 themselves (if needed), launches through SKSE.
2. Short verify-in-game checklist from CHANGES.md; optional live checks via DevBench.
3. Logs: run `logsum` on Papyrus/SKSE/crash logs before reading them.
4. Update CHANGES.md ("Deployed", "Verified in game: yes/no") and the bot's memory (paths, versions, project status).

## 7. Shared maps (LOCATIONS.md)

For any project with places, references, or IDs that several bots use, keep one `LOCATIONS.md` (see `templates/LOCATIONS.example.md`): plugin-relative IDs only (`XXXXXX:Plugin.esp`), never runtime load-order FormIDs; mark anything not re-verified.
