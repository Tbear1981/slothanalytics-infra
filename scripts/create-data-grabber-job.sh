#!/usr/bin/env bash
# Create or update the Pipeline job "from SCM" via jenkins-cli (no GUI).
#
# Prereqs:
#   - jenkins/cli/jenkins-cli.jar (./scripts/download-cli.sh)
#   - jenkins/.env with JENKINS_URL, JENKINS_AUTH, and GIT_URL (see .env.example)
#
# Usage:
#   cd jenkins && ./scripts/create-data-grabber-job.sh
#   JENKINS_JOB_NAME=my-job ./scripts/create-data-grabber-job.sh
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
GIT_URL="${GIT_URL:-}"
GIT_CREDENTIALS_ID="${GIT_CREDENTIALS_ID:-}"
GIT_BRANCH="${GIT_BRANCH:-*/main}"
TEMPLATE="$ROOT/job-xml/data-grabber-pipeline.xml.template"
CLI="$ROOT/scripts/jenkins-cli.sh"

if [[ -z "$GIT_URL" ]]; then
  echo "Set GIT_URL in jenkins/.env (HTTPS clone URL of this repo)." >&2
  exit 1
fi

if [[ ! -f "$ROOT/cli/jenkins-cli.jar" ]]; then
  echo "Run: $ROOT/scripts/download-cli.sh" >&2
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if ! command -v perl >/dev/null 2>&1; then
  echo "perl is required for templating." >&2
  exit 1
fi

GIT_URL="$GIT_URL" GIT_CREDENTIALS_ID="$GIT_CREDENTIALS_ID" GIT_BRANCH="$GIT_BRANCH" perl -pe '
  s/@GIT_URL@/$ENV{GIT_URL}/g;
  s/@GIT_CREDENTIALS_ID@/$ENV{GIT_CREDENTIALS_ID}/g;
  s/@GIT_BRANCH@/$ENV{GIT_BRANCH}/g;
' "$TEMPLATE" > "$TMP"

echo "Applying job XML for: $JOB_NAME"
echo "  GIT_URL=$GIT_URL"
echo "  GIT_BRANCH=$GIT_BRANCH"
echo "  credentialsId=${GIT_CREDENTIALS_ID:-"(empty — public repo OK)"}"

if "$CLI" get-job "$JOB_NAME" >/dev/null 2>&1; then
  echo "Updating existing job..."
  "$CLI" update-job "$JOB_NAME" < "$TMP"
else
  echo "Creating job..."
  "$CLI" create-job "$JOB_NAME" < "$TMP"
fi

echo "Done. Open Jenkins → $JOB_NAME → Build Now (or: ./scripts/trigger-build.sh)"
