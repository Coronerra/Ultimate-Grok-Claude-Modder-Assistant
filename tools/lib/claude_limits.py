#!/usr/bin/env python3
"""Claude Code usage-limit state for delegate-claude.

Claude Code doesn't report plan usage to non-interactive (-p) runs, so this tracks it from the
outside: when a run comes back with "You've hit your ... limit · resets <time>", the limit and its
reset time are saved, and the coordinator (Grok) can check before delegating.

State folder: $DELEGATE_STATE or ~/.claude-engineer
  limit.json   present only while the engineer is blocked
  usage.tsv    one line per run: epoch, mode, package, estimated cost USD, ok|limit|error

  claude_limits.py check-run <run.json> <stderr-file|-> <mode> <package>   -> exit 3 if a limit was hit
  claude_limits.py status [--json]                                         -> exit 3 while blocked
  claude_limits.py gate [model]                                             -> exit 3 while blocked
  claude_limits.py clear
"""
import json
import os
import re
import sys
import time
from datetime import datetime, timedelta

STATE = os.environ.get("DELEGATE_STATE") or os.path.join(os.path.expanduser("~"), ".claude-engineer")
LIMIT = os.path.join(STATE, "limit.json")
USAGE = os.path.join(STATE, "usage.tsv")
BLOCKED = 3
UNKNOWN_RESET_WAIT = 3600  # reset time not readable: retry after an hour

# "You've hit your session limit · resets 3:45pm", "... weekly limit · resets Mon 12:00am",
# "... Opus limit ...", "... monthly spend limit ...", older "usage limit reached".
LIMIT_RE = re.compile(r"(you've|you have) hit your ([a-z' -]*?)limit|usage limit reached|rate limit.*reached",
                      re.IGNORECASE)
RESET_RE = re.compile(r"resets?\s+(?:at\s+)?(?:(mon|tue|wed|thu|fri|sat|sun)[a-z]*\.?\s+)?(\d{1,2})(?::(\d{2}))?\s*([ap]m)?",
                      re.IGNORECASE)
DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]


def parse_reset(text, now=None):
    """Best effort: local wall-clock reset time from the message -> epoch seconds, or None."""
    m = RESET_RE.search(text or "")
    if not m:
        return None
    day, hh, mm, ap = m.group(1), int(m.group(2)), int(m.group(3) or 0), (m.group(4) or "").lower()
    if ap == "pm" and hh != 12:
        hh += 12
    elif ap == "am" and hh == 12:
        hh = 0
    if hh > 23 or mm > 59:
        return None
    now = now or datetime.now()
    t = now.replace(hour=hh, minute=mm, second=0, microsecond=0)
    if day:
        ahead = (DAYS.index(day.lower()[:3]) - now.weekday()) % 7
        t += timedelta(days=ahead)
        if t <= now:
            t += timedelta(days=7)
    elif t <= now:
        t += timedelta(days=1)
    return int(t.timestamp())


def load_limit():
    try:
        with open(LIMIT, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def blocked_now(lim):
    if not lim:
        return False
    until = lim.get("retry_after") or 0
    return time.time() < until


def fmt(epoch):
    return datetime.fromtimestamp(epoch).strftime("%a %Y-%m-%d %H:%M %Z").strip()


def record(mode, pkg, cost, outcome):
    os.makedirs(STATE, exist_ok=True)
    with open(USAGE, "a", encoding="utf-8") as f:
        f.write(f"{int(time.time())}\t{mode}\t{pkg}\t{cost:.4f}\t{outcome}\n")


def spend_since(seconds):
    total, runs, limits = 0.0, 0, 0
    cutoff = time.time() - seconds
    try:
        with open(USAGE, encoding="utf-8") as f:
            for line in f:
                p = line.rstrip("\n").split("\t")
                if len(p) < 5 or float(p[0]) < cutoff:
                    continue
                runs += 1
                total += float(p[3] or 0)
                limits += p[4] == "limit"
    except (OSError, ValueError):
        pass
    return total, runs, limits


def check_run(run_json, stderr_file, mode, pkg):
    try:
        with open(run_json, encoding="utf-8") as f:
            d = json.load(f)
    except (OSError, ValueError):
        d = {}
    err = ""
    if stderr_file != "-" and os.path.exists(stderr_file):
        with open(stderr_file, encoding="utf-8", errors="replace") as f:
            err = f.read()[-4000:]
    text = f"{d.get('result') or ''}\n{err}"
    cost = d.get("total_cost_usd") if isinstance(d.get("total_cost_usd"), (int, float)) else 0.0
    is_err = bool(d.get("is_error")) or d.get("subtype") not in (None, "success") or not d
    m = LIMIT_RE.search(text) if (is_err or d.get("api_error_status") == 429) else None
    if m:
        line = next((ln.strip() for ln in text.splitlines() if LIMIT_RE.search(ln)), m.group(0))
        reset = parse_reset(line)
        kind = (m.group(2) or "usage ").strip() or "usage"
        lim = {
            "blocked": True,
            "kind": kind,
            "message": line[:300],
            "detected_at": int(time.time()),
            "resets_at": reset,
            "retry_after": reset if reset else int(time.time()) + UNKNOWN_RESET_WAIT,
            "model_specific": bool(re.search(r"\b(opus|sonnet|haiku|fable|mythos)\b", kind, re.I)),
        }
        os.makedirs(STATE, exist_ok=True)
        with open(LIMIT, "w", encoding="utf-8") as f:
            json.dump(lim, f, indent=1)
        record(mode, pkg, cost, "limit")
        print(f"limit:    ENGINEER BLOCKED: {lim['message']}")
        print(f"          Grok covers until {fmt(lim['retry_after'])}"
              + ("" if reset else " (reset time not readable: retry then)")
              + ". Check with: delegate-claude limits")
        if lim["model_specific"]:
            print("          This limit is for one model family only: retry with --model <another model>.")
        return BLOCKED
    record(mode, pkg, cost, "error" if is_err else "ok")
    if not is_err and os.path.exists(LIMIT):
        os.remove(LIMIT)  # a successful run means the engineer is back
    return 0


def status(as_json=False):
    lim = load_limit()
    blocked = blocked_now(lim)
    day = spend_since(86400)
    week = spend_since(7 * 86400)
    if as_json:
        print(json.dumps({
            "available": not blocked,
            "limit": lim if blocked else None,
            "last_24h": {"est_cost_usd": round(day[0], 4), "runs": day[1], "limit_hits": day[2]},
            "last_7d": {"est_cost_usd": round(week[0], 4), "runs": week[1], "limit_hits": week[2]},
        }, indent=1))
    else:
        if blocked:
            print(f"engineer: BLOCKED ({lim.get('kind')} limit): {lim.get('message')}")
            print(f"          retry after {fmt(lim['retry_after'])}; until then Grok covers (see the skill).")
        elif lim:
            print(f"engineer: probably AVAILABLE again (the {lim.get('kind')} limit's reset time "
                  f"{fmt(lim['retry_after'])} has passed; the next run confirms and clears it)")
        else:
            print("engineer: AVAILABLE (no limit hit recorded)")
        print(f"runs:     last 24h {day[1]} (est. ${day[0]:.2f}), last 7 days {week[1]} (est. ${week[0]:.2f})")
        print("note:     estimated API-price cost from delegate-claude runs only; your plan's real usage bars")
        print("          (shared with claude.ai chats) are at claude.ai Settings > Usage, or /usage in Claude Code.")
    return BLOCKED if blocked else 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "check-run" and len(argv) == 6:
        return check_run(*argv[2:6])
    if cmd == "status":
        return status("--json" in argv)
    if cmd == "gate":
        lim = load_limit()
        model = argv[2] if len(argv) > 2 else ""
        if blocked_now(lim) and lim.get("model_specific") and model and \
                not re.search(r"\b%s\b" % re.escape(lim.get("kind", "").split()[0]), model, re.I):
            return 0  # e.g. Opus limit hit, but this run asked for another model
        if blocked_now(lim):
            print(f"delegate-claude: engineer is BLOCKED ({lim.get('kind')} limit) until {fmt(lim['retry_after'])}. "
                  "Grok covers this job (see the skill), or pass --force to try anyway.", file=sys.stderr)
            return BLOCKED
        return 0
    if cmd == "clear":
        if os.path.exists(LIMIT):
            os.remove(LIMIT)
        print("limit state cleared")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
