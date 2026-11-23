# Creation Kit for Skyrim VR: setup guide (generic)

Community-sourced research notes on running the Skyrim SE Creation Kit against a Skyrim VR install managed by Mod Organizer 2. Verify every version number and depot ID yourself before relying on it; these were current when the notes were written (Nov 2026) and may be stale.
Labels: **[cited]** = public source given. **[author's notes]** = from the original author's private research notes (not included in this kit). **[UNCERTAIN]** = conflicting or unconfirmed sources; check before relying on it.
Kit rules still apply (see `docs/WORKFLOW.md`): only the Installer bot installs on the PC, nothing happens without the owner's go, no writes while Skyrim or MO2 is open, backups go to `<BACKUP_ROOT>` (e.g. `<BACKUP_ROOT>\`), and `modlist.txt` / `plugins.txt` / `loadorder.txt` are never edited by hand or by a tool.

Placeholders: `<VR_MO2_DIR>` = your VR MO2 instance folder, `<SKYRIMVR_GAME_ROOT>` = your SkyrimVR game folder, `<PROFILE>` = your MO2 profile name.

---

## 0. Short answer
1. **Check whether you already have an SE Creation Kit.** A flat SE install that has `CreationKit` with **CKPE** (`CKPE.dll`, `CKPE.SkyrimSE.dll`, `CKPEBins`, `winhttp.dll`) plus folders like `CreationKit 1.6.1378.1 backup` and `CreationKit 1.7.99 backup` was set up with the CK Downgrade Patcher, so that CK is probably **1.6.1378.1, downgraded from 1.7.99** [INFERRED; the patcher "creates backups for 1.7.99, 1.6.1378.1 ..." per https://www.nexusmods.com/skyrimspecialedition/mods/190110].
2. **Recommended setup:** give the VR MO2 instance its own copy of CK 1.6.1378.1, kept as an MO2 mod and deployed with the Root Builder plugin, plus the latest CKPE. Then point the Papyrus source folder at a merged set of vanilla, SKSEVR and VR-mod sources. This is the community guide's recommended method for VR [cited: infernalryan, "How to Install Skyrim Creation Kit", 23 Jul 2026, https://www.nexusmods.com/skyrimspecialedition/articles/12296, sections 1.2, 2.2.2, 3.1].
3. **Header 1.71 is fine in VR if you run Skyrim VR ESL Support**, because it rewrites 1.71 headers to 1.70 in memory at load time [author's notes]. Don't drop the header to 1.70 by hand unless a specific tool requires it (§7).

---

## 1. Getting the Creation Kit (Steam, Bethesda.net, ownership, version)
- **Steam only.** The SSE CK is the Steam tool "Skyrim Special Edition: Creation Kit", app **1946180**, released on Steam 25 Apr 2022 [cited: https://steamdb.info/app/1946180/patchnotes/]. The guide says "GOG and other platforms do not support the Creation Kit" [cited: article 12296, Overview]. The old Bethesda.net launcher route no longer exists [UNCERTAIN: I found no current official page for this; I'm going by the Steam app's 2022 release date and the guide's "Steam only" line].
- **There is no VR Creation Kit.** VR users use the SSE CK [cited: article 12296 §1.3].
- **Ownership:** the *latest* CK needs `steam_api64.dll` from the latest Skyrim SE, so you need to **own SSE**, but you don't have to have SSE installed. People who own only VR can't launch the latest CK. They download CK 1.6.438, downgrade it to 1.5.73 and use CKPE [cited: article 12296 §2.2.2.2, §2.2.2.4 and the FAQ "Why can't I use the latest version ... if I only own Skyrim VR?"]. If you own SSE, the owner path applies.
- **Current version:** Steam now serves **CK 1.7.99**, which goes with Skyrim SE **1.7.104**. The CK Downgrade Patcher turns 1.7.99 back into 1.6.1378.1, 1.5.73 or 1.5.3 [cited: https://www.nexusmods.com/skyrimspecialedition/mods/190110, uploaded 30 Aug 2026, updated 2 Sep 2026]. The July 2026 guide still calls **1.6.1378.1** the latest, so it is older than 1.7.99 [cited: article 12296 §2.2.2.2]. SteamDB shows the CK app record changed again on 18 Nov 2026; I couldn't tell what changed [UNCERTAIN].
- **Which version to use for VR:** **1.6.1378.1.** It's a common, well-tested version, CKPE supports it, and the guide's depot manifests point at it [cited: CKPE supported list "1.5.3, 1.5.73, 1.6.438, 1.6.1130, 1.6.1378.1 and 1.7.99.0", https://www.nexusmods.com/skyrimspecialedition/mods/71371]. **[UNCERTAIN]** Nobody has reported CK 1.7.99 against VR data, and I have no source on what 1.7.99 changes in saved plugins. Avoid it for VR until someone has.

### Steps (owner of SSE, VR target)
1. In Steam, search for **Skyrim Special Edition: Creation Kit** and click **Add to Library**. **Don't install it** [cited: article 12296 §2.1].
2. Open the Steam console (`steam://nav/console`) and run these one at a time, waiting for "Depot download complete" after each [cited: article 12296 §2.2.2.2, Option 1 = 1.6.1378.1]:
   - `download_depot 1946180 1946182 7716046898922594451`
   - `download_depot 1946180 1946183 9161772268289920525`
   - VR users who own SSE also need the SSE runtime DLL: `download_depot 489830 489832 8042843504692938467`. From that depot you only take `steam_api64.dll` [cited: same section and §2.2.2.3.2].
   - **Shortcut, UNTESTED:** if you already have a flat SE install with a `CreationKit 1.6.1378.1 backup` folder, copy `CreationKit.exe` and its files from there instead. List that folder's contents first.
3. Build one folder named `Creation Kit`. Put both CK depots' contents in it. Extract `Data\Scripts.zip` **inside that folder's `Data`**, then copy the SSE `steam_api64.dll` into the `Creation Kit` folder (it goes into the root part in step 7) [cited: §2.2.2.3.1-2].

---

## 2. Install against the VR data folder, or a separate SE install?
| | Against VR data (through VR MO2) | Separate SE install (flat) |
|---|---|---|
| Masters | Sees the real VR masters, including **`SkyrimVR.esm`**, which the VR load order uses as an implicit master [author's notes] | Has no `SkyrimVR.esm`, so it can't open plugins that list it as a master. SE masters (1.6.1170) are not the VR 1.4.15 masters |
| Mods | Sees the VR mod list and load order through MO2 | Sees a different mod list. Plugins built there need a check in VR before use |
| Risk | CK and its root files sit in the VR game root while you use them, unless they're managed by Root Builder (§3) | Can't touch VR files at all |
| Use it for | Editing VR plugins (your VR plugins and patches) | Pure SE work, or learning the tool |
- **What the community recommends:** install the CK **as an MO2 mod in the instance you're modding**, deployed with Root Builder, "the recommended installation method for all game versions ... required for Skyrim VR users" [cited: article 12296 §2.2.2]. That keeps the game folder vanilla and lets you switch the CK files on only while you use them [cited: §1.2].
- **Strings:** if your VR masters are the original 1.4.15 files (no USSEP or SSE-master upgrade), you don't need the "Skyrim VR strings" mod [cited: §3.2]. Whether the VR masters are really 1.4.15 originals is **[UNCERTAIN]**; the Installer bot should check their hashes.

---

## 3. MO2 setup (Root Builder, the CK mod, the executable)
4. **Root Builder** (MO2 plugin by kezyma, https://www.nexusmods.com/skyrimspecialedition/mods/31720) lets MO2 manage files that live in the game *root*, not `Data` [cited: article 12296 §2.2.2.1]. Extract it into `<MO2>\plugins\rootbuilder`, restart MO2, and check that it shows under **Tools > Tool Plugins**. Whether the VR instance already has it: **[UNCERTAIN]**; the Installer bot should check `<VR_MO2_DIR>\plugins\`.
5. **Root Builder mode, [UNCERTAIN]:** Root Builder can *copy* root files into the game folder at launch and remove them afterwards, or link them. If MO2 or the CK crashes, copied files can be left in `<SKYRIMVR_GAME_ROOT>\` [game path from the SKSE log: box (author's notes)]. After the first session, check that the game root is clean.
6. **Watch out for root DLLs (INFERRED):** CKPE loads through a proxy `winhttp.dll` in the game root. If the VR root already has its own `winhttp.dll`, `dxgi.dll` or `d3d11.dll` (ReShade, VRPerfKit, OpenComposite and the like), the CK will load those too. Check what's in the VR root before adding CKPE. CKPE's own warning about ENB is "use ckpe_loader.exe" [cited: https://www.nexusmods.com/skyrimspecialedition/mods/71371, "Issue"].
7. **Make the CK mod** [cited: article 12296 §2.2.2.5.2]:
   - Inside `Creation Kit`, create `root\`. Move **everything except `Data\`** (CreationKit.exe, the `Papyrus Compiler` folder, `steam_api64.dll`, DLLs and INIs) into `root\`.
   - Move the *contents* of `Data\` (the CK's `.bsa`/`.esm` files if any, plus the extracted `Source\Scripts\...`) up into `Creation Kit\`, then delete the empty `Data\`.
   - Move `Creation Kit` into `<VR_MO2_DIR>\mods\`, press F5 in MO2 and enable it. If MO2 flags missing data, choose **Ignore missing data**.
   - **Rule reminder:** enabling a mod changes `modlist.txt`. That is MO2's job, but on this PC it needs the owner's go and the Installer bot does it.
8. **Add CKPE as a second mod** (§4) the same way: Manual install, put every file under `root\`, enable it [cited: article 12296 §3.1.2].
9. **MO2 executable** [cited: article 12296 §4.1.2]:
   - Title: `Creation Kit VR`.
   - Start in: the game root, `<SKYRIMVR_GAME_ROOT>`.
   - Binary: type `<SKYRIMVR_GAME_ROOT>\CreationKit.exe` by hand. You can't browse to it because only Root Builder puts it there.
   - Arguments: none.
   - Tick **Override Steam AppID** and enter **1946180**.
   - **Always start the CK from MO2**, so it sees the virtual `Data` (MO2 has no merged Data folder).
10. **First launch:** the CKPE first-time window appears; click **Continue**, then **Apply changes and close**. If asked to unpack `Scripts.zip`, answer **No** (you already extracted it). When the vanilla masters load, **Yes to All** on the warnings is expected [cited: article 12296 §4.2 and FAQ].
11. **If the CK never opens a window**, the `steam_api64.dll` is almost always the wrong one [cited: FAQ]. Per the guide, owners who run a non-latest game (VR counts) must disable the CK mod before launching Skyrim, because its `steam_api64.dll` would otherwise replace the game's [cited: §4.3, "All other users"]. **Do that for VR: CK mod off whenever you play.**

---

## 4. CK Platform Extended vs SSE CK Fixes
- **SSE CreationKit Fixes** (Nukem) is **superseded**; don't install it. The **Unofficial Creation Kit Patch** is incompatible with CKPE [cited: article 12296 §3.3].
- **CKPE** (perchik71) is the continuation of SSE CK Fixes and supports CK **1.5.3, 1.5.73, 1.6.438, 1.6.1130, 1.6.1378.1 and 1.7.99.0**. The Nexus page's last update is **7 Nov 2026** [cited: https://www.nexusmods.com/skyrimspecialedition/mods/71371]. A third-party mirror lists the current file as "0.6-b821" [cited: https://skyrimspecialedition.2game.info/detail.php?id=71371; UNCERTAIN, not the official page]. The latest GitHub release is "Release (a2abacd8)", 26 Oct 2026, with assets `ckpe-sse-master-a2abacd8.zip` and `-noavx2-` [cited: GitHub API for https://github.com/Perchik71/Creation-Kit-Platform-Extended/releases].
- The [community guide](https://www.nexusmods.com/skyrimspecialedition/articles/12296) (its §2.2.2.4) notes that the 1.6.438 build VR-only owners download "is not compatible with CKPE", so they downgrade to 1.5.73. Its install notes:
  - **AVX2:** pick the regular build if Steam > Help > System Information says "AVX2: Supported", otherwise noavx2.
  - **Files:** extract everything next to `CreationKit.exe`. `ckpe_loader.exe` should end up there.
  - **SSE Address Library:** SSE also needs CKPE's own address library under `CKPEBins\` [cited: https://github.com/Perchik71/Creation-Kit-Platform-Extended README "Installation"].
- **Settings file:** `CreationKitPlatformExtended.toml` (no longer an `.ini`) [cited: SSE defaults https://raw.githubusercontent.com/Perchik71/Creation-Kit-Platform-Extended/master/Stuffs/SSE/CreationKitPlatformExtended.toml]. Settings that matter here, with their line numbers in that file:
  - `bAllowSaveESM=true` (line 21): "Allow saving master files directly & setting them as the active file". **Set it to `false`** so the CK can't save over a master.
  - `bAllowMasterESP=true` (line 22): "Allow ESP files to act as master files while saving". **Keep it `true`.** Without it the CK drops ESP masters and leaves orphaned records [author's notes].
  - `bSupportFormat171=true` (line 40): only matters for editors older than 1.6.1130, and when on, "plugins will be saved in a new format".
  - `bOwnArchiveLoader=true` (line 28): loads mod BSAs.
  - `[FaceGen] bDisableAutoFaceGen=true` (line 76): no FaceGen written on save. Keep it.
  - `bSkipTopicInfoValidation=true` (line 20), `bGenerateCrashdumps`.
  - Settings can be changed later with `CKPE.Installer.exe`, started from MO2 [cited: article 12296 §4.2].

---

## 5. `CreationKitCustom.ini` / `CreationKitPrefs.ini`
Put these in **`CreationKitCustom.ini` in the game root**, inside the CK mod's `root\` folder. The `*Custom.ini` file overrides the default INI and survives updates [cited: https://falloutck.uesp.net/wiki/Initialization_File, "INI Custom" (the FO4 wiki, same mechanism); SSE location confirmed by CKPE's author in https://github.com/Perchik71/Creation-Kit-Platform-Extended/issues/88].
```ini
[General]
bAllowMultipleMasterLoads=1
bAllowMultipleMasterFiles=1

[Messages]
bBlockMessageBoxes=1

[Papyrus]
sScriptSourceFolder = "Data\Source\Scripts"
```
- **`bAllowMultipleMasterLoads=1`**: lets the CK load several masters together; without it you get "multiple master file selected load. load operation aborted" [cited: https://www.nexusmods.com/skyrimspecialedition/articles/5619; https://falloutck.uesp.net/wiki/Initialization_File; the mirror's troubleshooting adds `bAllowMultipleMasterFiles=1`, https://skyrimspecialedition.2game.info/detail.php?id=71371, UNCERTAIN whether the SSE CK reads that second key].
- **`bBlockMessageBoxes=1`**: stops the flood of warning popups at load [cited: article 5619].
- **`bAllowMasterESP`** is **not** a CK INI key. It belongs to CKPE's toml (§4) [cited: CKPE SSE toml line 22].
- **`SResourceArchiveList2`**: only needed when a plugin uses assets in BSAs the CK doesn't load. Article 5619 lists the SE + CC archives. In VR, list your own BSAs, or rely on CKPE `bOwnArchiveLoader` [UNCERTAIN which approach is needed with MO2 + CKPE].
- **`CreationKitPrefs.ini`** holds window and UI preferences; nothing in it is required for VR [UNCERTAIN: no primary doc found].
- The guide warns that many old CreationKitCustom.ini tweaks predate CKPE and no longer apply [cited: article 12296 §3.3 "Legacy CreationKitCustom.ini tweaks"]. Keep the INI short.
- **PC-pull idea:** if you already have a working flat-SE CK, its `CreationKitCustom.ini` and `CreationKitPlatformExtended.toml` show what already works. The Installer bot can copy them to the box read-only for comparison.

---

## 6. Papyrus: compiling against SKSEVR and VR sources
Facts:
- **Where the SSE CK puts sources:** its `Scripts.zip` unpacks to **`Data\Source\Scripts`**, which is the SSE default (LE used `Data\Scripts\Source`) [cited: https://forums.nexusmods.com/topic/5161950-correct-order-of-script-files/; CKPE issue #88].
- **Where SKSEVR puts sources:** its readme says to copy its `.psc` files into **`Data\Scripts\Source\`** "and add them to your include path" [author's notes]. SKSEVR 2.0.12 ships about 62 `.psc` files.
- **Several source folders inside the CK: [UNCERTAIN].** CKPE's author shows `sAdditionalImports = "$(source);.\Data\Scripts\Source"` for SSE (issue #88). Older forum answers say the Skyrim CK ignores `sAdditionalImports` (https://forums.nexusmods.com/topic/6012563-trouble-compiling-script-fragment-that-use-skse/). The safe method is one merged folder.
- **Why compile against SKSEVR rather than SKSE64:** the VR `.psc` files only declare natives that exist in VR. SE-only functions then fail at compile time instead of failing silently in game. Many VR mod frameworks use VR-only natives too (VRIK, HIGGS, PapyrusUtil VR, Papyrus Extender VR).
- The VR data tree has an incomplete vanilla script set (about 100 files, `Debug`/`Message` missing). Installing the CK's `Scripts.zip` fixes that gap [author's notes].

Steps:
12. In the CK mod you already have `Source\Scripts\` (vanilla, from `Scripts.zip`). Dawnguard, Hearthfire and Dragonborn sources may be in subfolders. Copy them up into `Source\Scripts` in plugin order (Dawnguard, HearthFires, Dragonborn) so the CK finds them [cited: forum topic 5161950].
13. Make a **separate MO2 mod** called `CK Sources - SKSEVR + VR` holding `Source\Scripts\*.psc`, built from:
    - the 62 SKSEVR files (from the SKSEVR 2.0.12 7z);
    - the `.psc` sources the VR mods ship: VRIK, HIGGS, PapyrusUtil VR, Papyrus Extender VR, SkyUI VR and so on, usually under each mod's `Scripts\Source` or `Source\Scripts`.

    Give it **higher priority than the CK mod** so SKSEVR's `Actor.psc`, `Game.psc` and the rest replace the vanilla copies. Nothing in the real game folder is overwritten. Note SE-built sources that a VR patch replaces (for example PO3 SE vs VR): use the **VR** copy.
14. Set `sScriptSourceFolder = "Data\Source\Scripts"` (§5). Compiled `.pex` files go to `Data\Scripts`, which under MO2 means the **overwrite** folder. Move them into the right mod after each session.
15. **Command line, often easier and the way the team works:** use `Papyrus Compiler\PapyrusCompiler.exe` from the CK with `-f="TESV_Papyrus_Flags.flg" -i="<your src>;<SKSEVR src>;<VR mod srcs>;<vanilla Source\Scripts>" -o="<out>"`. Import folders are searched in order, so put SKSEVR before vanilla [cited: the import-path pattern in forum topic 6012563; first-found order is UNCERTAIN, verify with one test compile]. The box toolchain notes for Caprica (`--game skyrim`, `--ignorecwd`) are in the memory file above, and `papyrus build` uses the same ordering [author's notes].
16. **Fragments** (TIF/QF) can only be compiled from inside the CK and are fragile. Add an empty fragment, close and reopen the window, then edit [author's notes].

---

## 7. ESL, form version and header version (1.70 vs 1.71)
- **Form version:** SSE and VR both use form version **44**. Mutagen's SkyrimVR constants are copied from SSE with the "same form version" [author's notes]. Form 44 is not a VR problem.
- **Header:** CK 1.6.1130 and later write **HEDR 1.71**. Older CKs can't open 1.71 files without CKPE [cited: article 12296 FAQ "MASTERFILE is a higher version"]. 1.71 also turns on the extended light-plugin FormID range **001-7FF** [cited: xEdit 4.1.5b notes, https://github.com/tes5edit/tes5edit/releases].
- **VR + Skyrim VR ESL Support:** the installed SKSEVR plugin hooks the file reader. When it reads a header above 1.70 and at most 1.71 it sets the version to 1.70 and logs "Emulated old header version for {file}" [author's notes]. It also adds ESL and AE extended-ESL support [author's notes]. Confirm it is live by finding `skyrimvresl.dll` in your VR SKSE log. **So with that plugin installed, a 1.71 plugin saved by CK 1.6.x loads in VR without changes.**
- **xEdit:** use **TES5VREdit** (xEdit in `-tes5vr` mode), **4.1.5f or later**. 4.1.5c added VR ESL support when the VR ESL plugin is detected, and 4.1.5f fixed the extended low range for TES5VR [cited: https://github.com/tes5edit/tes5edit/releases; https://github.com/TES5Edit/TES5Edit/issues/1305]. Start it through MO2, or it will invent a wrong load order.
- **Setting the header back to 1.70 in xEdit:** select the plugin, open File Header > `HEDR - Header` > `Version`, double-click, type `1.70`, then close and save [cited, reverse of the 1.70→1.71 procedure: https://www.nexusmods.com/skyrimspecialedition/articles/9721]. **When it's safe:** only when the plugin has **no FormIDs below `xx000800`** of its own and none of its masters is 1.71 with extended-range records. **Risk:** xEdit treats a sub-0x800 ID in a 1.70 file as a hard override of a base-game record, and plugins whose masters are 1.71 "should themselves be version 1.71 ... otherwise there will be errors" [cited: xEdit 4.1.5b notes; https://www.nexusmods.com/skyrimspecialedition/articles/9691]. With the VR ESL plugin present this is rarely needed. Do it only when a specific old tool refuses 1.71, keep a backup, and redo it after every CK save.
- **Team ESL rule:** new IDs stay in `xx000800`-`xx000FFF` until a below-0x800 plugin has been verified on your VR + skyrimvresl runtime, and FormIDs a save already references are never compacted [author's notes]. Whether CK 1.6.1378.1 hands out new light-plugin IDs below 0x800 is **[UNCERTAIN]**; check every new ESL in TES5VREdit after saving.
- **ESL flag:** the CK doesn't reliably set the ESM flag when converting [author's notes]. Set and check flags in xEdit. Don't ESL-flag plugins that ship with a DLL, such as VRIK or HIGGS [author's notes].

---

## 8. Pitfalls checklist
1. **Never set a master (`.esm`, or your own project masters) as the active file.** Set CKPE `bAllowSaveESM=false` (§4). Only the one plugin you mean to edit is active.
2. **Back up the plugin before every CK session and every save**, to `<BACKUP_ROOT>\<date>-ck-<plugin>\` with a hash. The CK can look like it saved while the `.esp` disappears or is corrupted, and it removes null records on load [author's notes].
3. **Load-order lists stay untouched.**
   - Before starting the CK, hash `<VR_MO2_DIR>\profiles\<PROFILE>\plugins.txt` and `loadorder.txt`, and check them again after closing it. If they changed, put the backup back and tell the Installer bot.
   - Never let the CK, xEdit, LOOT or any other tool rewrite them.
   - Whether the CK itself writes `plugins.txt` under MO2 is **[UNCERTAIN]**. MO2 regenerates `loadorder.txt` itself (the file header says so: (author's notes)).
4. **The CK mod is off while you play VR**, because of its SSE `steam_api64.dll` (§3 step 11).
5. **Never run the CK while Skyrim VR is running**, and do no PC writes while MO2 or Skyrim is open.
6. **Collect new output from MO2's overwrite folder** after each session (new `.esp`, `.pex`, FaceGen, `CreationKitPrefs.ini` changes) and move it into a named mod. Don't leave it in overwrite.
7. **Don't open a live save's scripted plugin to delete records.** Removing scripted forms leaves orphans. "Lobotomize" instead.
8. **Expect "Yes to All" warnings** for vanilla masters; that's normal [cited: article 12296 FAQ]. Look at the warnings for *your* plugin.
9. **Don't open ESP-mastered plugins without `bAllowMasterESP=true`**, or the CK strips the ESP masters [author's notes].
10. **Keep the game outside Program Files.** VR is at `<SKYRIMVR_GAME_ROOT>`, which is fine; protected folders break CK writes [cited: https://www.reddit.com/r/skyrimmods/comments/1rjpsvr/creation_kit_not_reading_skse_script/, top comment].
11. **The CK doesn't regenerate navmesh or precombines safely for VR-specific records you haven't checked.** Navmesh creation is CK-only and xEdit can only delete it [author's notes]. Test any navmesh edit in the headset.
12. **Team roles:** in this kit's workflow the designated plugin-editor bot is the only bot that edits ESPs, and the Installer bot is the only installer. CK work by the owner is their call, but bots should not save plugins from the CK.

---

## 9. What's uncertain, and what to check first on the PC (read-only, by the Installer bot)
- If you reuse a flat-install CK: whether it really is 1.6.1378.1 (file version of `CreationKit.exe`), and the contents of its `CreationKitCustom.ini` / `.toml`.
- Whether Root Builder is installed in `<VR_MO2_DIR>\plugins\`, and which proxy DLLs (`winhttp.dll`, `dxgi.dll`, `d3d11.dll`, `openvr_api.dll` replacements) sit in the VR game root.
- Hashes of the VR masters (1.4.15 originals, or SSE masters).
- CK 1.7.99 with VR data: no report found. What changed in Steam's CK on 18 Nov 2026: unknown.
- `sAdditionalImports` in the SSE CK: conflicting sources. Import order in PapyrusCompiler: verify with one test compile.
- Whether the CK writes `plugins.txt` under MO2. Whether CK 1.6.x assigns ESL IDs below 0x800.
