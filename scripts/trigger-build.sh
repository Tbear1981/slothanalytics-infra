#!/usr/bin/env bash
# Trigger a build of the Pipeline job (optional parameters).
#
# Usage:
#   ./scripts/trigger-build.sh
#   ./scripts/trigger-build.sh RUN_ES_DRY_RUN=false
#   ./scripts/trigger-build.sh RUN_ES_DRY_RUN=true DRY_RUN_DATE=2026-05-09
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

JOB_NAME="${JENKINS_JOB_NAME:-datafordeler-regnskab}"
CLI="$ROOT/scripts/jenkins-cli.sh"

if [[ $# -eq 0 ]]; then
  exec "$CLI" build "$JOB_NAME"
fi

PARAM_ARGS=()
for arg in "$@"; do
  PARAM_ARGS+=(-p "$arg")
done
exec "$CLI" build "$JOB_NAME" "${PARAM_ARGS[@]}"
