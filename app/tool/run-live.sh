#!/usr/bin/env bash
# Runs the app on the connected device/simulator with LIVE 2026 World
# Cup data (football-data.org free tier).
#
# One-time setup — put your token in the gitignored app/.secrets file:
#   echo 'FOOTBALLDATA_TOKEN=your_token' > app/.secrets
# (free token: https://www.football-data.org/client/register)
#
# Usage, from anywhere:
#   app/tool/run-live.sh                 # flutter run with live data
#   app/tool/run-live.sh -d <device-id>  # extra args pass through
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .secrets ]]; then
  echo "app/.secrets not found. Create it with:" >&2
  echo "  echo 'FOOTBALLDATA_TOKEN=your_token' > app/.secrets" >&2
  echo "Free token: https://www.football-data.org/client/register" >&2
  exit 1
fi

# shellcheck disable=SC1091
source .secrets
: "${FOOTBALLDATA_TOKEN:?FOOTBALLDATA_TOKEN missing from app/.secrets}"

exec flutter run --dart-define=FOOTBALLDATA_TOKEN="$FOOTBALLDATA_TOKEN" "$@"
