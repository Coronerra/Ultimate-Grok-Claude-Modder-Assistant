# Claude Code as the team's engineer

The Grok Bot stays the coordinator and the only Installer. Claude Code runs on the same Linux box and builds code fixes as staged packages when the coordinator calls `tools/bin/delegate-claude`. It never reaches the modding PC.

```
Owner --plan OK--> Grok (coordinator) --TASK.md--> Claude Code (engineer) --package--> Grok
Grok --review--> Claude Code (fresh, read-only) --VERDICT--> Grok --summary--> Owner --go--> Grok (Installer) --> PC
```

## 1. Install on the box
Requires a Claude **Pro, Max, Team or Enterprise** plan (the free plan doesn't include Claude Code), or a Claude Console API key.

```bash
# Option A: npm (Node.js 22+). Don't use sudo.
npm install -g @anthropic-ai/claude-code
# Option B: native installer or Debian/Ubuntu apt repo: see https://code.claude.com/docs/en/setup
claude --version && claude doctor
```

## 2. Sign in without a browser on the box
The box has no browser, so sign in once from your phone or PC:

```bash
claude setup-token          # prints a URL: open it on your phone/PC, approve, copy the token it shows
```
Store the token where only the bot's user can read it, and load it into the environment for `delegate-claude`:
```bash
install -m 600 /dev/null ~/.config/claude-token
printf 'export CLAUDE_CODE_OAUTH_TOKEN=%s\n' '<token>' > ~/.config/claude-token
echo '[ -f ~/.config/claude-token ] && . ~/.config/claude-token' >> ~/.bashrc
```
The token lasts a year, uses your subscription, and can only make model requests. Never paste it into a chat, a task or a kit file.

Alternative (pay per use): set `ANTHROPIC_API_KEY` with a key from https://platform.claude.com. If both are set, the API key wins, and `-p` runs always use it.

## 3. Configure
| Variable | Default | What |
| --- | --- | --- |
| `CAPRICA_CMD` | `caprica` | Command that compiles Papyrus on the box (e.g. a small wrapper that runs Caprica under Wine). It is the only build command allowed by default. |
| `DELEGATE_BUDGET` | `5` | USD cap per run (client-side estimate) |
| `DELEGATE_MAX_TURNS` | `80` | Turn cap per run |
| `CLAUDE_BIN` | `claude` | Path to Claude Code |

`delegate-claude` adds `TEAM-RULES.md` to every run, so the engineer always gets the team rules.

Then copy `templates/CLAUDE.md.template` to `<PACKAGES_DIR>/CLAUDE.md` (the folder that holds every package folder) and fill it in. Claude Code reads every `CLAUDE.md` from its working folder up to `/`, so one file there covers every package. If none is found, `delegate-claude` falls back to the template and warns you.

**Keeping it current:** after every finished job, Grok copies the report's "Lessons for CLAUDE.md" into it (step 6 of the `delegate-to-claude-code` skill). That file is the engineer's long-term memory.

**Moving the bot's knowledge over:** ask the Grok Bot to add to "Project facts" in that `CLAUDE.md` from its memory: mod variants, plugin names, FormID map (`XXXXXX:Plugin.esp`), dependencies, known traps. That's how a month of context reaches the engineer without feeding it files again.

## 4. Smoke test
```bash
source tools/env.sh
mkdir -p ~/packages/smoke-test/live && echo 'Scriptname Hello extends Quest' > ~/packages/smoke-test/live/Hello.psc
delegate-claude new ~/packages/smoke-test --dry-run --task "x"   # shows the exact claude command
delegate-claude new ~/packages/smoke-test --budget 0.5 \
  --task "Read live/Hello.psc and reply with one line saying what it declares. Do not create files."
delegate-claude new ~/packages/smoke-test --budget 0.5 \
  --task "Run: ssh localhost true"        # must be DENIED (shows in the summary)
```

## 5. Usage limits: who covers when the engineer is out
On a Pro or Max plan, Claude Code shares a 5-hour limit and a weekly limit with your claude.ai chats. A `-p` run gets no usage bars, so `delegate-claude` watches from the outside:
- A run that comes back with "You've hit your session/weekly/Opus limit · resets <time>" exits **3**. It saves the limit and reset time in `~/.claude-engineer/limit.json` (or `$DELEGATE_STATE`), and every run is logged in `usage.tsv`.
- `delegate-claude limits` shows AVAILABLE or BLOCKED, the reset time, and how many runs went to the engineer in the last 24 hours and 7 days, with their estimated cost. `--json` gives the same for scripts, `--probe` checks with one tiny request, and `--clear` forgets a recorded limit.
- While blocked, `new`, `follow` and `review` refuse to start (exit 3) unless you pass `--force`. A model-specific limit (Opus, Sonnet) doesn't block runs that ask for another model with `--model`.
- A successful run clears the recorded limit.
- The reset time is read from the message and taken as the box's local time. If it can't be read, Grok retries after an hour.
- The cost figures are Claude Code's API-price estimates, not your plan percentage. Your real bars are at claude.ai **Settings > Usage**, or `/usage` in an interactive Claude Code session.
- While the engineer is out, Grok covers urgent jobs itself and marks them for review (see the skill, "When the engineer is out").

## 6. What the safety rules do, and don't
`delegate-claude` runs Claude Code in the package folder with:
- `--permission-mode acceptEdits`: edits inside the package (and mkdir/cp/mv/touch) need no approval. Edits anywhere else are denied, because no person is there to approve them (`--permission-prompts none`).
- Reads: free inside the package and the `--ref` folders. `~/.ssh` and the Claude credentials file are explicitly denied.
- Bash: Claude Code's built-in read-only commands, plus `sha256sum`, `diff`, the exact hashing pipeline, `$CAPRICA_CMD`, and anything you add with `--allow-bash`. Everything else is denied.
- Explicit deny rules: ssh, scp, sftp, rsync, psenc, tailscale, curl, wget, git push. Web search and fetch stay off unless you pass `--web`.
- `live/`, the `--ref` folders and the kit's templates and docs can't be edited.
- `review` runs in `plan` mode: it reads and runs checks, but never edits.

These rules are enforced by Claude Code itself, not by the model, so a prompt can't talk its way past them. Two limits to know:
1. Bash deny rules match the command text. Running a program by its full path, or inside `sh -c`, wouldn't match a deny rule. That's why the real guard is the **allow list**: those forms aren't on it, so they're denied too. Keep `--allow-bash` rules narrow, and never allow `sh`, `bash`, `python3 *`, `env`, `xargs *` or `find *`. Each of those can run anything.
2. Claude Code runs as the Linux user that starts it. **Strongest setup:** run it as a separate user (e.g. `engineer`) that doesn't have the PC's SSH key, owns `<PACKAGES_DIR>`, and can't read the Grok Bot's home. For example, with `CLAUDE_BIN='sudo -u engineer -H claude'` (sudoers: allow the bot user to run only `claude` as `engineer`, and pass `CLAUDE_CODE_OAUTH_TOKEN`).

## 7. Files
| File | Used by |
| --- | --- |
| `tools/bin/delegate-claude` | Coordinator: `new`, `follow`, `review`, `status`, `limits` |
| `tools/lib/claude_limits.py` | Usage-limit detection and state for `delegate-claude` (`~/.claude-engineer/`) |
| `skills/delegate-to-claude-code/SKILL.md` | Coordinator's how-to (import into the Grok Bot) |
| `templates/bot-roster/claude-code-engineer.md` | Role card for the roster |
| `templates/CLAUDE.md.template` | Engineer's standing rules, copied to `<PACKAGES_DIR>/CLAUDE.md` |
| `<package>/.claude-session`, `<package>/.claude-runs/` | Session ID and full JSON of every run (cost, denials). Not part of the package: don't copy them to the PC. |

Docs: headless runs https://code.claude.com/docs/en/headless · permissions https://code.claude.com/docs/en/permissions · auth https://code.claude.com/docs/en/authentication
