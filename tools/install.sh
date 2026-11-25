#!/usr/bin/env bash
# Grok modding kit: one-step install on the bot's Linux box (never on the modding PC).
#
#   bash tools/install.sh [--skills-dir DIR] [--no-shell-rc] [--force-skills]
#
#   --skills-dir DIR   copy skills/* into DIR/<skill-name>/ (or set GROK_SKILLS_DIR).
#                      Existing different copies are backed up to DIR/<name>.bak-<timestamp>.
#                      If omitted on an interactive terminal you are asked; otherwise skipped.
#   --no-shell-rc      don't add `source .../tools/env.sh` to ~/.bashrc and ~/.profile
#   RTK_SRC=/path/to/rtk   also copy + SHA-256-verify the rtk oss 1.2.0 binary
#   PYTHON=python3.13      choose the interpreter for the venv (3.11+)
#
# What it does:
#   1. creates the venv INSIDE the kit (tools/venv) and installs tools/requirements.txt
#      with --require-hashes; adds tools/lib to the venv (boxkit.pth)
#   2. puts tools/bin on PATH via tools/env.sh (and your shell rc unless --no-shell-rc)
#   3. installs the skills into the folder you choose
#   4. smoke-tests the tools
# It never edits tracked kit files: tomd/chunk/digest-watch keep `#!/usr/bin/env python3`
# and re-exec themselves under tools/venv, so `sha256sum -c SHA256SUMS` still passes.
# Only untracked paths are created: tools/venv, tools/cache, tools/bin/rtk (optional).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
KIT_HOME="$(dirname "$HERE")"
PY="${PYTHON:-python3}"
VENV="$HERE/venv"
SKILLS_DIR="${GROK_SKILLS_DIR:-}"
SHELL_RC=1
FORCE_SKILLS=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="$2"; shift 2 ;;
    --skills-dir=*) SKILLS_DIR="${1#*=}"; shift ;;
    --no-shell-rc) SHELL_RC=0; shift ;;
    --force-skills) FORCE_SKILLS=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "install.sh: unknown option $1" >&2; exit 2 ;;
  esac
done

echo "== 1/4 venv + pinned packages ($VENV)"
"$PY" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' \
  || { echo "install.sh: need Python 3.11+ (set PYTHON=...)" >&2; exit 1; }
"$PY" -m venv "$VENV"
"$VENV/bin/pip" install -q -U pip
"$VENV/bin/pip" install -q --require-hashes -r "$HERE/requirements.txt"
SITE="$("$VENV/bin/python" -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')"
echo "$HERE/lib" > "$SITE/boxkit.pth"
mkdir -p "$HERE/cache"
if [[ -n "${RTK_SRC:-}" ]]; then
  cp "$RTK_SRC" "$HERE/bin/rtk"; chmod +x "$HERE/bin/rtk"
  (cd "$HERE/bin" && sha256sum -c rtk.sha256)
fi
for t in "$HERE"/bin/*; do
  [[ "$t" == *.sha256 ]] && continue
  [[ -x "$t" ]] || { echo "NOTE: $t not executable (zip lost modes?): run chmod +x tools/bin/*" >&2; }
done

echo "== 2/4 PATH"
LINE="[ -f \"$HERE/env.sh\" ] && . \"$HERE/env.sh\"   # grok-modding-kit"
if [[ $SHELL_RC -eq 1 ]]; then
  for rc in "$HOME/.bashrc" "$HOME/.profile"; do
    touch "$rc"
    if grep -qF "# grok-modding-kit" "$rc"; then
      echo "   $rc already sources a grok-modding-kit env.sh (left as is)"
    else
      printf '\n%s\n' "$LINE" >> "$rc"; echo "   added to $rc"
    fi
  done
else
  echo "   skipped shell rc; run:  source \"$HERE/env.sh\""
fi

echo "== 3/4 skills"
if [[ -z "$SKILLS_DIR" && -t 0 ]]; then
  read -r -p "   Folder to install skills into (blank = skip): " SKILLS_DIR || true
fi
if [[ -n "$SKILLS_DIR" ]]; then
  SKILLS_DIR="${SKILLS_DIR/#\~/$HOME}"
  mkdir -p "$SKILLS_DIR"
  TS="$(date +%Y%m%d-%H%M%S)"
  for s in "$KIT_HOME"/skills/*/; do
    n="$(basename "$s")"; dst="$SKILLS_DIR/$n"
    if [[ -d "$dst" ]] && ! diff -rq "$s" "$dst" >/dev/null 2>&1; then
      if [[ $FORCE_SKILLS -eq 0 && -t 0 ]]; then
        read -r -p "   $dst exists and differs. Back it up and replace? [y/N] " ans || ans=n
        [[ "$ans" == [yY]* ]] || { echo "   kept $dst"; continue; }
      fi
      mv "$dst" "$dst.bak-$TS"; echo "   backed up $dst -> $dst.bak-$TS"
    fi
    mkdir -p "$dst"; cp -R "$s." "$dst/"; echo "   installed $n"
  done
  echo "   Import or register these folders as skills/workflows in your Grok Bot (see SETUP.md Part C)."
else
  echo "   skipped (re-run with --skills-dir DIR, or import skills/ by hand)"
fi

echo "== 4/4 smoke test"
# shellcheck disable=SC1091
. "$HERE/env.sh"
ok=1
for t in tomd chunk digest-watch devbench whats-here psenc delegate-claude; do
  "$HERE/bin/$t" --help >/dev/null 2>&1 && echo "   $t ok" || { echo "   $t FAILED"; ok=0; }
done
"$VENV/bin/python" -c "import boxkit" && echo "   boxkit ok" || { echo "   boxkit FAILED"; ok=0; }
if [[ -x "$HERE/bin/rtk" ]] || command -v rtk >/dev/null 2>&1 || [[ -n "${RTK:-}" ]]; then
  "$HERE/bin/logsum" --help >/dev/null && echo "   logsum ok"
else
  echo "   logsum: needs rtk oss 1.2.0 (RTK_SRC=/path/to/rtk bash tools/install.sh)"
fi
echo "   optional CLIs (spriggit, champollion, dream_archivetool): see docs/OPTIONAL-CLIS.md"
command -v "${CLAUDE_BIN:-claude}" >/dev/null 2>&1 && echo "   claude found: $("${CLAUDE_BIN:-claude}" --version 2>/dev/null)" || echo "   Claude Code (the engineer, recommended): not installed; see docs/CLAUDE-CODE-ENGINEER.md"
[[ $ok -eq 1 ]] && echo "Installed. Open a new shell or: source \"$HERE/env.sh\"" || { echo "Install finished with failures." >&2; exit 1; }
