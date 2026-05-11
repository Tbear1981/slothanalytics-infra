#!/usr/bin/env bash
# Create or update the "create GitHub repo" Pipeline job (loads Jenkinsfile from this repo).
#
# Prereqs: same as create-data-grabber-job.sh — jenkins-cli.jar + jenkins/.env with GIT_URL.
#
# Usage:
#   cd jenkins && ./scripts/create-github-repo-job.sh
#   JENKINS_JOB_NAME=bootstrap-github-repo ./scripts/create-github-repo-job.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

JOB_NAME="${JENKINS_JOB_NAME:-create-github-repo}"
GIT_URL="${GIT_URL:-}"
GIT_CREDENTIALS_ID="${GIT_CREDENTIALS_ID:-}"
GIT_BRANCH="${GIT_BRANCH:-*/main}"
TEMPLATE="$ROOT/job-xml/create-github-repo-pipeline.xml.template"
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
echo "  Script path: jenkins/Jenkinsfile.githubCreateRepo"

if "$CLI" get-job "$JOB_NAME" >/dev/null 2>&1; then
  echo "Updating existing job..."
  "$CLI" update-job "$JOB_NAME" < "$TMP"
else
  echo "Creating job..."
  "$CLI" create-job "$JOB_NAME" < "$TMP"
fi

echo "Done. Add Jenkins credential github-token-repo-create (see GITHUB_CREATE_REPO.md), then Build with Parameters."
