# Bot roster templates

Generic role cards for a small team of Grok Bots working on one modding PC. Copy a card into a new bot's instructions/memory and fill in the `<placeholders>`. You can run every role in one bot to start; split roles out once projects grow. The one rule that never bends: **exactly one Installer bot writes to the PC.**

| Card | Role | PC access |
| --- | --- | --- |
| `installer-bot.md` | Installer | read + write (the only writer) |
| `chief-of-staff.md` | Coordinator | none / read-only |
| `researcher-bot.md` | Researcher(s) | read-only |
| `specialist-bot.md` | Specialist(s), incl. the single plugin editor | read-only; stages on the box |
| `claude-code-engineer.md` | Engineer: Claude Code, called by the coordinator with `delegate-claude` | none; stages on the box |
| `ROSTER.example.md` | The team's live roster | n/a |
