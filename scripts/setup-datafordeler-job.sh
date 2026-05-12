#!/usr/bin/env bash
# One-shot repeatable setup: ensure Jenkins CLI + create/update datafordeler Pipeline job (no Jenkins UI).
#
# Prerequisites:
#   cp .env.example .env
#   Set JENKINS_URL, JENKINS_AUTH, GIT_URL (HTTPS URL of datafordeler_regnskab).
#
# Optional secret file credential (same ID as Jenkinsfile: data-grabber-env):
#   DATA_GRABBER_ENV_FILE=/path/to/data-grabber-crawler-ts/.env ./scripts/setup-datafordeler-job.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
chmod +x "$ROOT/scripts"/*.sh 2>/dev/null || true

if [[ ! -f "$ROOT/.env" ]]; then
  echo "Missing $ROOT/.env — copy .env.example and set JENKINS_URL, JENKINS_AUTH, GIT_URL." >&2
  exit 1
fi

if [[ ! -f "$ROOT/cli/jenkins-cli.jar" ]]; then
  "$ROOT/scripts/download-cli.sh"
fi

"$ROOT/scripts/jenkins-cli.sh" version

if [[ -n "${DATA_GRABBER_ENV_FILE:-}" && -f "${DATA_GRABBER_ENV_FILE}" ]]; then
  "$ROOT/scripts/import-data-grabber-env-credential.sh" "${DATA_GRABBER_ENV_FILE}"
fi

"$ROOT/scripts/create-data-grabber-job.sh"

echo ""
echo "Trigger a build: ${ROOT}/scripts/trigger-build.sh"
echo "Parameters example: ${ROOT}/scripts/trigger-build.sh RUN_ES_DRY_RUN=false"
