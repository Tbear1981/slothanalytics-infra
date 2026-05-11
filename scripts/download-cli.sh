#!/usr/bin/env bash
# Fetch jenkins-cli.jar from a running Jenkins (must match your server version).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

URL="${JENKINS_URL:-http://127.0.0.1:8080}"
OUT="$ROOT/cli/jenkins-cli.jar"

mkdir -p "$ROOT/cli"
curl -fsSL "${URL%/}/jnlpJars/jenkins-cli.jar" -o "$OUT"
echo "Downloaded: $OUT"
echo "Try: JENKINS_URL=$URL ./scripts/jenkins-cli.sh help"
