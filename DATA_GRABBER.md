# Jenkins: data-grabber pipeline (`datafordeler_regnskab`)

This doc applies to the **[datafordeler_regnskab](https://github.com/Tbear1981/datafordeler_regnskab)** application repo: root **`Jenkinsfile`**, **`data-grabber-crawler-ts`**, optional Virk ES **dry-run**.

**`GIT_URL` when using scripts here:** For **`create-data-grabber-job.sh`**, set **`GIT_URL`** in **`.env`** to the **HTTPS clone URL of `datafordeler_regnskab`** (the app repo), **not** `slothanalytics-infra`.

## Jenkins requirements

- **Pipeline** from SCM (GitHub or other Git remote).
- **Docker Pipeline** plugin and a Jenkins agent that can run **`docker`** (Docker daemon on the host, or DinD — same setup as any Docker-based pipeline).

If you **cannot** use Docker agents, edit the app repo’s **`Jenkinsfile`** `agent { docker { ... } }` block and replace it with `agent any`, and install **Node ≥ 20** on the agent.

## Repeatable setup (CLI only — no Jenkins UI)

From this (**slothanalytics-infra**) repo root: **`cp .env.example .env`**, then set **`JENKINS_URL`**, **`JENKINS_AUTH`** (user:API token), and **`GIT_URL`** (HTTPS URL of **`datafordeler_regnskab`**).

### One shot: credential + job

Fill **`data-grabber-crawler-ts/.env`** locally from **`.env.example`** (same fields as for dry-run). Do **not** commit real secrets.

```bash
chmod +x scripts/*.sh
DATA_GRABBER_ENV_FILE=/absolute/path/to/datafordeler_regnskab/data-grabber-crawler-ts/.env \
  ./scripts/setup-datafordeler-job.sh
```

This downloads **`jenkins-cli.jar`** if needed, imports **Secret file** credential ID **`data-grabber-env`** (or override with **`JENKINS_CREDENTIAL_ID_DATA_GRABBER_ENV`**), creates or updates the Pipeline-from-SCM job, then you can run **`./scripts/trigger-build.sh`**.

### Job only (no secret upload)

```bash
./scripts/download-cli.sh          # once
./scripts/create-data-grabber-job.sh
./scripts/trigger-build.sh         # optional: RUN_ES_DRY_RUN=false
```

### Credential only

```bash
./scripts/import-data-grabber-env-credential.sh /path/to/data-grabber-crawler-ts/.env
```

Uses **`credentials-templates/data-grabber-env.xml.template`** and **`create-credentials-by-xml`** / **`update-credentials-by-xml`**. If Jenkins rejects the XML (plugin version mismatch), add the **Secret file** once in the UI, then adjust the template to match the XML your server expects (Plain Credentials plugin version).

## Fallback: secret file credential in the UI

1. Fill **`data-grabber-crawler-ts/.env`** locally from **`.env.example`** (at minimum **`S3_BUCKET`** for the crawler CLI — dry-run still loads env).
2. Jenkins → **Manage Jenkins** → **Credentials** → (your domain) → **Add Credentials**.
3. Kind: **Secret file**.
4. Upload that `.env` file.
5. **ID** must be exactly: **`data-grabber-env`** (the **`Jenkinsfile`** references this ID).

## Fallback: create the job in the UI

1. **New Item** → name e.g. `datafordeler-regnskab` → **Pipeline** → OK.
2. **Pipeline** → Definition: **Pipeline script from SCM**.
3. SCM: **Git**, URL = **`datafordeler_regnskab`** clone URL, credentials if private, branch `main` (or `*/main`).
4. **Script Path**: **`Jenkinsfile`**.
5. Save → **Build Now**.

Optional settings when using scripts instead of the UI: **`GIT_CREDENTIALS_ID`**, **`GIT_BRANCH`**, **`JENKINS_JOB_NAME`** in **`.env`**.

**`create-data-grabber-job.sh`** reads **`job-xml/data-grabber-pipeline.xml.template`** and runs **`create-job`** or **`update-job`**.

If Jenkins rejects the XML (plugin mismatch), create the job once in the UI, run **`./scripts/jenkins-cli.sh get-job datafordeler-regnskab > backup.xml`**, and compare.

### Parameters

| Parameter        | Default | Meaning                                              |
|------------------|---------|------------------------------------------------------|
| `RUN_ES_DRY_RUN` | true    | Run Virk ES scroll query with **`--dry-run`** (no S3 uploads). |
| `DRY_RUN_DATE`   | empty   | Optional **`YYYY-MM-DD`**; empty uses yesterday in `TZ`. |

Turn **`RUN_ES_DRY_RUN`** off to only run **npm ci / build / lint** (no secrets needed if you remove or skip the last stage — currently the stage is skipped when false, so **no credential required** for build-only).

## Scheduled / GitHub triggers

Use **Build periodically**, **Poll SCM**, or a **GitHub webhook** on the same job like any other Jenkins pipeline.

## Production crawl (not in default Jenkinsfile)

Real uploads need the same `.env` plus network access to AWS/S3 and Virk. Add another stage or a separate job that runs e.g.:

`npm run crawl -- daily`

(without `--dry-run`) — only after you trust schedules and secrets.
