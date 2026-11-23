# Grok modding kit: put tools/bin on PATH. Safe to source more than once.
#   export KIT_HOME=/path/to/grok-modding-kit   (optional; auto-detected)
#   source "$KIT_HOME/tools/env.sh"
_kit_here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export KIT_HOME="${KIT_HOME:-$(dirname "$_kit_here")}"
export KIT_LIB="${KIT_LIB:-$KIT_HOME/tools/lib}"
export KIT_CACHE="${KIT_CACHE:-$KIT_HOME/tools/cache}"
export KIT_VENV="${KIT_VENV:-$KIT_HOME/tools/venv}"
case ":${PATH}:" in
  *:"$KIT_HOME/tools/bin":*) ;;
  *) PATH="$KIT_HOME/tools/bin:${PATH}" ;;
esac
export PATH
unset _kit_here
