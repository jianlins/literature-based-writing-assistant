#!/bin/zsh
set -euo pipefail

# Uses the dedicated profile selected in config/browser-profile.local.json when
# available; otherwise creates a temporary task-only profile. When changing the
# port, make the same change in the local .codex/config.toml.
PORT=9222
PORT_FROM_ARGUMENT=false
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROFILE_CONFIG="${SCRIPT_DIR}/../../config/browser-profile.local.json"

usage() {
  cat <<'EOF'
Usage: .agents/scripts/start-research-chrome.sh [--port PORT]

Starts Google Chrome with a task-only profile and Chrome DevTools Protocol
enabled.
EOF
}

while (( $# )); do
  case "$1" in
    --port)
      [[ $# -ge 2 ]] || { echo "Missing value for --port." >&2; exit 2; }
      PORT="$2"
      PORT_FROM_ARGUMENT=true
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -f "$PROFILE_CONFIG" && "$PORT_FROM_ARGUMENT" == false ]]; then
  if command -v node >/dev/null 2>&1; then
    CONFIG_PORT="$(node -e 'const c = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); const v = c && c.cdp_port; if (v !== undefined && (!Number.isInteger(v) || v < 1 || v > 65535)) process.exit(2); process.stdout.write(v === undefined ? "" : String(v))' "$PROFILE_CONFIG")" || {
      echo "Invalid browser profile configuration: $PROFILE_CONFIG" >&2
      exit 1
    }
  elif command -v python3 >/dev/null 2>&1; then
    CONFIG_PORT="$(python3 -c 'import json, sys; value = json.load(open(sys.argv[1], encoding="utf-8")).get("cdp_port"); assert value is None or (type(value) is int and 1 <= value <= 65535); print("" if value is None else value, end="")' "$PROFILE_CONFIG")" || {
      echo "Invalid browser profile configuration: $PROFILE_CONFIG" >&2
      exit 1
    }
  else
    echo "Cannot read $PROFILE_CONFIG: install Node.js or Python 3, or remove the local configuration to use a temporary profile." >&2
    exit 1
  fi
  [[ -z "$CONFIG_PORT" ]] || PORT="$CONFIG_PORT"
fi

if ! [[ "$PORT" =~ '^[0-9]+$' ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "Port must be an integer from 1 through 65535." >&2
  exit 2
fi

if command -v curl >/dev/null 2>&1 && \
  curl --fail --silent --max-time 2 "http://127.0.0.1:${PORT}/json/version" | grep -q '"webSocketDebuggerUrl"'; then
  echo "A CDP browser is already available on port ${PORT}; reuse it instead of starting Chrome."
  exit 0
fi

PROFILE_DIR=""
PROFILE_SOURCE="temporary"
if [[ -f "$PROFILE_CONFIG" ]]; then
  if command -v node >/dev/null 2>&1; then
    PROFILE_DIR="$(node -e 'const c = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); if (!c || typeof c.user_data_dir !== "string" || !c.user_data_dir) process.exit(2); process.stdout.write(c.user_data_dir)' "$PROFILE_CONFIG")" || {
      echo "Invalid browser profile configuration: $PROFILE_CONFIG" >&2
      exit 1
    }
  elif command -v python3 >/dev/null 2>&1; then
    PROFILE_DIR="$(python3 -c 'import json, sys; value = json.load(open(sys.argv[1], encoding="utf-8")).get("user_data_dir"); assert isinstance(value, str) and value; print(value, end="")' "$PROFILE_CONFIG")" || {
      echo "Invalid browser profile configuration: $PROFILE_CONFIG" >&2
      exit 1
    }
  else
    echo "Cannot read $PROFILE_CONFIG: install Node.js or Python 3, or remove the local configuration to use a temporary profile." >&2
    exit 1
  fi
  if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "Configured browser profile directory is unavailable: $PROFILE_DIR" >&2
    exit 1
  fi
  PROFILE_SOURCE="configured"
fi

if [[ -z "$PROFILE_DIR" ]]; then
  PROFILE_DIR="${TMPDIR:-/tmp}/research-browser-chrome-${PORT}"
  mkdir -p "$PROFILE_DIR"
fi

open -na "Google Chrome" --args \
  "--remote-debugging-port=${PORT}" \
  --user-data-dir="$PROFILE_DIR" \
  --no-first-run \
  --no-default-browser-check

echo "Started ${PROFILE_SOURCE} research browser on CDP port ${PORT}."

