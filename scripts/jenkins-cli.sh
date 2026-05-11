#!/usr/bin/env bash
# Wrapper for: java -jar jenkins-cli.jar -s http://127.0.0.1:8080/ ...
#
# Env:
#   JENKINS_URL     default http://127.0.0.1:8080
#   JENKINS_AUTH    optional user:apiToken (recommended once security is enabled)
#
# Examples:
#   ./scripts/download-cli.sh
#   ./scripts/jenkins-cli.sh help
#   JENKINS_AUTH=admin:xxx ./scripts/jenkins-cli.sh version
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

JAR="$ROOT/cli/jenkins-cli.jar"
URL="${JENKINS_URL:-http://127.0.0.1:8080}"

if [[ ! -f "$JAR" ]]; then
  echo "Missing $JAR — run first from repo jenkins/ folder:" >&2
  echo "  ./scripts/download-cli.sh" >&2
  exit 1
fi

AUTH_ARGS=()
if [[ -n "${JENKINS_AUTH:-}" ]]; then
  AUTH_ARGS=(-auth "$JENKINS_AUTH")
fi

exec java -jar "$JAR" -s "${URL%/}/" "${AUTH_ARGS[@]}" "$@"
