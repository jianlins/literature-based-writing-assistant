#!/usr/bin/env bash
set -euo pipefail

port=9222
port_from_argument=false
chrome_path=""
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
profile_config="${script_dir}/../../config/browser-profile.local.json"

usage() {
  cat <<'EOF'
Usage: .agents/scripts/start-research-chrome-linux.sh [--port PORT] [--chrome-path PATH]

Starts Google Chrome or Chromium with a task-only profile and Chrome DevTools
Protocol enabled. Supply --chrome-path when the browser is installed somewhere
nonstandard.
EOF
}

while (($#)); do
  case "$1" in
    --port)
      [[ $# -ge 2 ]] || { echo "Missing value for --port." >&2; exit 2; }
      port="$2"
      port_from_argument=true
      shift 2
      ;;
    --chrome-path)
      [[ $# -ge 2 ]] || { echo "Missing value for --chrome-path." >&2; exit 2; }
      chrome_path="$2"
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

if [[ -f "$profile_config" && "$port_from_argument" == false ]]; then
  if command -v node >/dev/null 2>&1; then
    config_port="$(node -e 'const c = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); const v = c && c.cdp_port; if (v !== undefined && (!Number.isInteger(v) || v < 1 || v > 65535)) process.exit(2); process.stdout.write(v === undefined ? "" : String(v))' "$profile_config")" || {
      echo "Invalid browser profile configuration: $profile_config" >&2
      exit 1
    }
  elif command -v python3 >/dev/null 2>&1; then
    config_port="$(python3 -c 'import json, sys; value = json.load(open(sys.argv[1], encoding="utf-8")).get("cdp_port"); assert value is None or (type(value) is int and 1 <= value <= 65535); print("" if value is None else value, end="")' "$profile_config")" || {
      echo "Invalid browser profile configuration: $profile_config" >&2
      exit 1
    }
  else
    echo "Cannot read $profile_config: install Node.js or Python 3, or remove the local configuration to use a temporary profile." >&2
    exit 1
  fi
  [[ -z "$config_port" ]] || port="$config_port"
fi

if ! [[ "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
  echo "Port must be an integer from 1 through 65535." >&2
  exit 2
fi

if command -v curl >/dev/null 2>&1 && \
  curl --fail --silent --max-time 2 "http://127.0.0.1:${port}/json/version" | grep -q '"webSocketDebuggerUrl"'; then
  echo "A CDP browser is already available on port ${port}; reuse it instead of starting Chrome."
  exit 0
fi

if [[ -n "$chrome_path" && ! -x "$chrome_path" ]]; then
  echo "The browser executable supplied with --chrome-path is not executable: $chrome_path" >&2
  exit 1
fi

if [[ -z "$chrome_path" ]]; then
  for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$candidate" >/dev/null 2>&1; then
      chrome_path="$(command -v "$candidate")"
      break
    fi
  done
fi

if [[ -z "$chrome_path" ]]; then
  cat >&2 <<'EOF'
Google Chrome or Chromium could not be found automatically.

Install a supported browser, or tell your coding assistant where it is
installed by providing the full path to its executable. For example:
  bash .agents/scripts/start-research-chrome-linux.sh --chrome-path /usr/bin/google-chrome

If a chatbot app called this script, paste this error and that executable path
into the chat. Do not provide a browser profile, login, password, or other
private data.
EOF
  exit 1
fi

# Use the dedicated profile selected in the app-neutral local configuration.
# Without one, create a temporary task-only profile. Keep the port synchronized
# with .codex/config.toml.
profile_dir=""
profile_source="temporary"
if [[ -f "$profile_config" ]]; then
  if command -v node >/dev/null 2>&1; then
    profile_dir="$(node -e 'const c = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")); if (!c || typeof c.user_data_dir !== "string" || !c.user_data_dir) process.exit(2); process.stdout.write(c.user_data_dir)' "$profile_config")" || {
      echo "Invalid browser profile configuration: $profile_config" >&2
      exit 1
    }
  elif command -v python3 >/dev/null 2>&1; then
    profile_dir="$(python3 -c 'import json, sys; value = json.load(open(sys.argv[1], encoding="utf-8")).get("user_data_dir"); assert isinstance(value, str) and value; print(value, end="")' "$profile_config")" || {
      echo "Invalid browser profile configuration: $profile_config" >&2
      exit 1
    }
  else
    echo "Cannot read $profile_config: install Node.js or Python 3, or remove the local configuration to use a temporary profile." >&2
    exit 1
  fi
  if [[ ! -d "$profile_dir" ]]; then
    echo "Configured browser profile directory is unavailable: $profile_dir" >&2
    exit 1
  fi
  profile_source="configured"
fi

if [[ -z "$profile_dir" ]]; then
  profile_dir="${TMPDIR:-/tmp}/research-browser-chrome-${port}"
  mkdir -p "$profile_dir"
fi

nohup "$chrome_path" \
  "--remote-debugging-port=${port}" \
  "--user-data-dir=${profile_dir}" \
  --no-first-run \
  --no-default-browser-check \
  >/dev/null 2>&1 &

echo "Started ${profile_source} research browser on CDP port ${port}."
