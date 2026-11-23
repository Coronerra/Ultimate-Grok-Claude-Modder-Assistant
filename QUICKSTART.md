# Quickstart

The shortest path from zero to a first **read-only** session. Full detail is in `SETUP.md`.

1. **Unpack the kit on the bot's box**, e.g. `~/grok-modding-kit`, and check it:
   ```bash
   cd ~/grok-modding-kit && sha256sum -c SHA256SUMS
   ```
2. **Install everything in one step** (venv, pinned packages, PATH, skills, smoke test):
   ```bash
   bash tools/install.sh --skills-dir <YOUR_SKILLS_FOLDER>
   source tools/env.sh                   # or open a new shell
   sha256sum -c SHA256SUMS               # still passes: install never edits kit files
   ```
   For `logsum`, download rtk oss 1.2.0 yourself and add `RTK_SRC=/path/to/rtk` in front of the install command (it verifies the SHA-256).
3. **Register the skills** in your Grok Bot from the folder you chose (or paste each `skills/<name>/SKILL.md`). Start with `getting-started-skyrim-modding` and `remote-skyrim-modding-session`. If DevBench is installed, also add `skyrim-whats-here`. See `CAPABILITIES.md` for everything else.
4. **On your modding PC:** unzip the whole kit and double-click **`install.bat`** (try `install.bat -DryRun` first to see what it would do). Pick **1 = Skyrim SE/AE** or **2 = Skyrim VR**, approve the Windows admin prompt, then answer each question; Enter always means No. It offers Python, Git, Tailscale and OpenSSH Server, creates your folders, checks your game folder and script extender (SKSE64 or SKSEVR), adds the bot's **public** SSH key, and prints your Tailscale IP and detected game/MO2 paths. Full steps: [`INSTALL.md`](INSTALL.md). Sign in to Tailscale when asked. Never share a password or private key. (Manual alternative: `SETUP.md` Part B.)
5. **Tell the bot:** "Run the getting-started Skyrim modding skill." It will ask your game edition, mod manager and profile, connect over Tailscale, and do one read-only scan.
6. **Review the ranked fix list.** Approve, strike, or ask. Nothing is written until you say go.
7. Copy `templates/` into a project folder before the first change: `LOCATIONS.example.md` → `LOCATIONS.md`, and use `CHANGES.template.md`, `SHA256SUMS-HOWTO.md` and `rollback.template.ps1` for every package.

Rules you'll see the bot follow: backups before edits, mod manager only, game and MO2 closed for writes, and load-order files are never touched by the bot.
