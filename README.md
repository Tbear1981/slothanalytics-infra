# slothanalytics-infra

Shared **Jenkins** operations for Sloth Analytics: run the controller with Docker Compose on a VPS, manage jobs via **`jenkins-cli`**, and ship templates for **bootstrapping GitHub repos** and **wiring CI to application repositories**.

Application source code lives in separate repos (for example **`datafordeler_regnskab`**). Those repos keep only a root **`Jenkinsfile`** (and app docs). **This repo** holds Jenkins itself plus XML/script tooling that references other repos via **`GIT_URL`**.

**GitHub:** [Tbear1981/slothanalytics-infra](https://github.com/Tbear1981/slothanalytics-infra) — transfer or fork to a **`slothanalytics`** org when you are ready; update clone URLs in your notes.

## Prerequisites

- Docker Engine + Docker Compose v2 (`docker compose`)
- Firewall: open **8080** (or whatever you set in `.env`) if you need the UI from your laptop

## Quick start

```bash
git clone https://github.com/Tbear1981/slothanalytics-infra.git
cd slothanalytics-infra
cp .env.example .env   # optional edits
docker compose up -d
```

Open **http://\<VPS-IP\>:8080** (or `localhost` if you tunnel).

### First-time unlock

```bash
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Paste the password in the UI, install **suggested plugins**, create an admin user.

## Jenkins CLI (`jenkins-cli.jar`)

The CLI JAR is served by your running Jenkins — download it once, then call **Java** on your machine (the host needs a **JRE/JDK**, not only Docker).

Put credentials in **`.env`** at the **repository root** (gitignored). Copy from `.env.example` and set `JENKINS_AUTH=user:api_token`. CLI scripts **auto-load** `.env` when present.

```bash
cp .env.example .env   # edit .env — never commit it
chmod +x scripts/*.sh
./scripts/download-cli.sh
./scripts/jenkins-cli.sh help
```

After you enable login, anonymous CLI calls usually fail. Create an **API token** (Jenkins → your user → **Account** → **Add new Token**), then:

```bash
export JENKINS_AUTH='youruser:your_api_token'
./scripts/jenkins-cli.sh version
./scripts/jenkins-cli.sh list-jobs
```

Optional: `export JENKINS_URL=http://your-vps:8080` if Jenkins is remote.

**Note:** This is **not** a GitHub secret — it is Jenkins user + API token for talking to **your** Jenkins server.

## GitHub: new commits on `main`

Two options:

1. **Webhook (recommended)** — In GitHub repo → Settings → Webhooks → Payload URL `http://YOUR_JENKINS/github-webhook/` (requires Jenkins **GitHub plugin** and a URL reachable from GitHub; use a reverse proxy + HTTPS in production).
2. **Poll SCM** — In the job / Multibranch config, set **Poll SCM** with schedule `H/5 * * * *` (~every 5 minutes). No inbound connection to Jenkins needed.

Create a **Multibranch Pipeline** job pointing at your GitHub repo, or a **Pipeline** job with “Pipeline script from SCM” and path **`Jenkinsfile`** in the **application** repo.

## Running pipelines that need Docker

The compose file can mount **`/var/run/docker.sock`** from the host (commented). That lets jobs run `docker` on the **host** daemon. Security note: jobs then have substantial control over the host; restrict who can run jobs and prefer dedicated agents for untrusted code.

Alternatively install **Docker CLI + Docker Compose** inside a **custom image** built `FROM jenkins/jenkins:lts-jdk17`.

## Backups

All Jenkins state lives in the named Docker volume **`slothanalytics_jenkins_home`**. Back it up regularly:

```bash
docker run --rm -v slothanalytics_jenkins_home:/from -v "$(pwd):/backup" alpine \
  tar czf /backup/jenkins_home_backup.tgz -C /from .
```

## Resource hints (same VPS as workloads)

- Give the VPS enough **RAM** (Jenkins + Java + your jobs; 2 GB is tight for heavy Docker builds).
- Put **`JENKINS_HOME`** on a disk with space; job workspaces and logs grow.
- Consider **separate agents** later if CPU contention hurts interactive Jenkins use.

## Application example: `datafordeler_regnskab`

The **[datafordeler_regnskab](https://github.com/Tbear1981/datafordeler_regnskab)** repo contains the pipeline definition at its root **`Jenkinsfile`**.

To register that job from this repo’s CLI, set **`GIT_URL`** in **`.env`** to the **HTTPS clone URL of `datafordeler_regnskab`**, then run **`./scripts/create-data-grabber-job.sh`**. Credentials for the crawler (`data-grabber-env`) are documented in **[DATA_GRABBER.md](DATA_GRABBER.md)**.

## Create GitHub repositories from Jenkins

Use **`Jenkinsfile.githubCreateRepo`** with Jenkins credential **`github-token-repo-create`**. For the Jenkins job’s SCM, use **`GIT_URL`** pointing at **this (`slothanalytics-infra`) repo** so Jenkins checks out this repo and runs that script.

See **[GITHUB_CREATE_REPO.md](GITHUB_CREATE_REPO.md)** and **`scripts/create-github-repo-job.sh`**.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Jenkins LTS, ports, volume |
| `.env.example` | Ports and timezone |
| `Jenkinsfile.example` | Declarative pipeline template with `pollSCM` |
| `Jenkinsfile.githubCreateRepo` | Parameterized job to **create GitHub repos** via API |
| `GITHUB_CREATE_REPO.md` | Token scopes + credential ID + job setup |
| `job-xml/create-github-repo-pipeline.xml.template` | Pipeline-from-SCM XML for the bootstrap job |
| `scripts/create-github-repo-job.sh` | **`create-job` / `update-job`** for that XML template |
| `DATA_GRABBER.md` | **datafordeler** job: credentials + `GIT_URL` = app repo |
| `scripts/download-cli.sh` | Downloads `cli/jenkins-cli.jar` from `/jnlpJars/` |
| `scripts/jenkins-cli.sh` | Runs CLI (`help`, `version`, `list-jobs`, …) |
| `scripts/create-data-grabber-job.sh` | **`create-job` / `update-job`** for the datafordeler pipeline template |
| `scripts/trigger-build.sh` | **`build`** with optional `-p name=value` params |
| `job-xml/data-grabber-pipeline.xml.template` | Pipeline-from-SCM job → checkout **app** repo, script **`Jenkinsfile`** |
