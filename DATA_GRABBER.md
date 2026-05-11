# Jenkins: data-grabber pipeline (`datafordeler_regnskab`)

This doc applies to the **[datafordeler_regnskab](https://github.com/Tbear1981/datafordeler_regnskab)** application repo: root **`Jenkinsfile`**, **`data-grabber-crawler-ts`**, optional Virk ES **dry-run**.

**`GIT_URL` when using scripts here:** For **`create-data-grabber-job.sh`**, set **`GIT_URL`** in **`.env`** to the **HTTPS clone URL of `datafordeler_regnskab`** (the app repo), **not** `slothanalytics-infra`.

## Jenkins requirements

- **Pipeline** from SCM (GitHub or other Git remote).
- **Docker Pipeline** plugin and a Jenkins agent that can run **`docker`** (Docker daemon on the host, or DinD — same setup as any Docker-based pipeline).

If you **cannot** use Docker agents, edit the app repo’s **`Jenkinsfile`** `agent { docker { ... } }` block and replace it with `agent any`, and install **Node ≥ 20** on the agent.

## One-time: secret file credential

1. Fill **`data-grabber-crawler-ts/.env`** locally from **`.env.example`** (at minimum **`S3_BUCKET`** for the crawler CLI — dry-run still loads env).
2. Jenkins → **Manage Jenkins** → **Credentials** → (your domain) → **Add Credentials**.
3. Kind: **Secret file**.
4. Upload that `.env` file.
5. **ID** must be exactly: **`data-grabber-env`** (the **`Jenkinsfile`** references this ID).

Do **not** commit real `.env` to Git.

## Create the job

### Option A — Jenkins UI

1. **New Item** → name e.g. `datafordeler-regnskab` → **Pipeline** → OK.
2. **Pipeline** → Definition: **Pipeline script from SCM**.
3. SCM: **Git**, URL = **`datafordeler_regnskab`** clone URL, credentials if private, branch `main` (or `*/main`).
4. **Script Path**: **`Jenkinsfile`**.
5. Save → **Build Now**.

### Option B — CLI (`jenkins-cli`)

From this (**slothanalytics-infra**) repository root (after **`cp .env.example .env`** and setting **`JENKINS_URL`** / **`JENKINS_AUTH`**):

1. Set **`GIT_URL`** to the **application** repo HTTPS URL (**`datafordeler_regnskab`**).
2. Optionally set **`GIT_CREDENTIALS_ID`**, **`GIT_BRANCH`**, **`JENKINS_JOB_NAME`**.

```bash
./scripts/download-cli.sh          # once: jenkins-cli.jar
./scripts/create-data-grabber-job.sh
./scripts/trigger-build.sh           # optional: RUN_ES_DRY_RUN=false
```

This reads **`job-xml/data-grabber-pipeline.xml.template`** and runs **`create-job`** or **`update-job`**.

If Jenkins rejects the XML (plugin mismatch), create the job once in the UI, run **`jenkins-cli get-job datafordeler-regnskab > backup.xml`**, and compare.

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
