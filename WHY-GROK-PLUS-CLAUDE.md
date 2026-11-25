# Why Grok + Claude Code?

Short version: **each one is strong where the other is weak.** Together they cover a whole modding job, from "I have an idea" (or "my game keeps crashing") to a tested, packaged, reversible install.

## What each one brings

| | **Grok (the coordinator)** | **Claude Code (the engineer)** |
| --- | --- | --- |
| Best at | Conversation, planning, quick turnaround, and creative writing of every kind, including explicit content for adult mods | Careful multi-file programming, compiling, debugging, reading big logs and codebases, docs, and reviews |
| Where it struggles | Long, exacting code work. It tends to burn out on big scripts and multi-step builds. | Explicit sexual writing (it follows Anthropic's policies, so the kit never asks it to). Plan usage limits. |
| Memory | Its own long-term memory of you, your PC and your projects | A `CLAUDE.md` file Grok keeps up to date, plus a saved session for each job |
| Touches your PC? | Yes. It's the only Installer, and only after your "go". | Never. It works only inside a package folder on Grok's box. |

## Why that split
1. **The writing goes where it's welcome.** Adult mods need explicit text, and Grok will write it. Claude Code still does all the engineering around it (scripts, scene JSON, FOMODs, MCMs) and leaves `[[GROK-WRITE: ...]]` markers where the text goes. Neither one is pushed into work it's bad at or won't do, and you never paste text back and forth by hand.
2. **The code goes to the specialist.** Papyrus mistakes are quiet and costly: a loop that never ends, a missing `None` check, a property baked into every save. Claude Code reads the real files, compiles with Caprica, and hands back diffs, checksums and a rollback script.
3. **A second pair of eyes on every change.** Before anything reaches you, a *fresh* Claude Code session that didn't build the package reviews it. It ends with `VERDICT: PASS` or `VERDICT: FIX`. Work never grades itself.
4. **One writer to your PC.** Only Grok, as the Installer, ever writes to your machine, and only after your own go. Claude Code can't reach the PC at all: no SSH, no network, and Bash limited to an allow list enforced by Claude Code itself, not by a prompt.
5. **Grok's load stays light.** Code, logs, docs, packaging and reviews all go to Claude Code. Grok keeps its energy for you, the plan, and the writing.
6. **Nobody gets stuck when limits hit.** If Claude Code hits its 5-hour or weekly limit, `delegate-claude` records when it resets. Grok tells you, covers urgent jobs itself, and has them reviewed once the engineer is back.

## The flow
```
You ──idea or problem──▶ Grok (plans, asks, writes TASK.md)
                           │
                           ├──▶ Claude Code: builds, compiles, diagnoses (staged package)
                           │        └─ leaves GROK-WRITE markers for explicit text
                           ├──▶ Grok fills the markers
                           ├──▶ Claude Code (fresh session): review → PASS / FIX
                           ▼
You ◀──summary, "not tested in game" list, cost── Grok
You ──"go"──▶ Grok (Installer): backup → install → verify → rollback ready
```

## Content: one rule
Every fictional theme is the modder's call. The team doesn't judge, lecture or water things down, whether the mod is a lore-friendly quest or something far darker. The one exception can't be changed: **no sexual content involving minors, ever.** Grok refuses it, Claude Code refuses it, and in code every sexual-scene actor search must exclude children. A review that finds a missing child check fails the package. Details in [`TEAM-RULES.md`](TEAM-RULES.md).

## Do I need both?
No, but you'll want both. Without Claude Code, the kit works as the original Grok-only kit, and Grok does everything itself. With Claude Code, you get the engineer, the independent reviews, and the tech-support diagnostics. Setup: [`docs/CLAUDE-CODE-ENGINEER.md`](docs/CLAUDE-CODE-ENGINEER.md).
