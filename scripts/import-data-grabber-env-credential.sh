#!/usr/bin/env bash
# Import or update Jenkins Secret file credential ID data-grabber-env from a local .env file (no GUI).
#
# Requires: cli/jenkins-cli.jar, .env with JENKINS_URL and JENKINS_AUTH.
# Plain Credentials plugin must be installed (same as UI "Secret file").
#
# Usage:
#   ./scripts/import-data-grabber-env-credential.sh /path/to/data-grabber-crawler-ts/.env
#   DATA_GRABBER_ENV_FILE=/path/to/.env ./scripts/import-data-grabber-env-credential.sh
#
# Override credential ID (must match Jenkinsfile):
#   JENKINS_CREDENTIAL_ID_DATA_GRABBER_ENV=data-grabber-env ./scripts/import-data-grabber-env-credential.sh ...
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT/.env"
  set +a
fi

ENV_FILE="${1:-${DATA_GRABBER_ENV_FILE:-}}"
CRED_ID="${JENKINS_CREDENTIAL_ID_DATA_GRABBER_ENV:-data-grabber-env}"
TEMPLATE="$ROOT/credentials-templates/data-grabber-env.xml.template"
CLI="$ROOT/scripts/jenkins-cli.sh"

if [[ -z "$ENV_FILE" || ! -f "$ENV_FILE" ]]; then
  echo "Provide a path to the secret file (e.g. data-grabber-crawler-ts/.env)." >&2
  echo "Usage: $0 /path/to/.env" >&2
  echo "   or: DATA_GRABBER_ENV_FILE=/path/to/.env $0" >&2
  exit 1
fi

if [[ ! -f "$ROOT/cli/jenkins-cli.jar" ]]; then
  echo "Run: $ROOT/scripts/download-cli.sh" >&2
  exit 1
fi

if ! command -v perl >/dev/null 2>&1; then
  echo "perl is required." >&2
  exit 1
fi

if base64 --help 2>&1 | grep -q -- '-w'; then
  B64="$(base64 -w0 < "$ENV_FILE")"
else
  B64="$(base64 < "$ENV_FILE" | tr -d '\n')"
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

CREDENTIAL_ID="$CRED_ID" BASE64_CONTENT="$B64" perl -pe '
  s/@CREDENTIAL_ID@/$ENV{CREDENTIAL_ID}/g;
  s/@BASE64_CONTENT@/$ENV{BASE64_CONTENT}/g;
' "$TEMPLATE" > "$TMP"

echo "Applying Secret file credential id=$CRED_ID (from $ENV_FILE)"

set +e
OUT_CREATE="$("$CLI" create-credentials-by-xml system::system::jenkins "(global)" < "$TMP" 2>&1)"
RC_CREATE=$?
set -e

if [[ $RC_CREATE -eq 0 ]]; then
  echo "Created credential $CRED_ID."
  exit 0
fi

set +e
OUT_UPDATE="$("$CLI" update-credentials-by-xml system::system::jenkins "(global)" "$CRED_ID" < "$TMP" 2>&1)"
RC_UPDATE=$?
set -e

if [[ $RC_UPDATE -eq 0 ]]; then
  echo "Updated credential $CRED_ID."
  exit 0
fi

echo "create-credentials failed ($RC_CREATE): $OUT_CREATE" >&2
echo "update-credentials failed ($RC_UPDATE): $OUT_UPDATE" >&2
exit 1
