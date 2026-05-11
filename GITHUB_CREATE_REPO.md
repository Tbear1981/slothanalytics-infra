# Jenkins: create GitHub repositories (API)

This repo includes **`Jenkinsfile.githubCreateRepo`** — a parameterized pipeline that calls GitHub’s REST API to **create a new repository** under your **user** or an **organization** (e.g. `slothanalytics`).

Secrets stay in **Jenkins credentials** (or are injected by other automation); nothing sensitive is committed to Git.

## One-time: GitHub token as Jenkins credential

1. Create a **classic PAT** or **fine-grained token** that may **create repositories**:
   - **Organization repos**: the token’s user/app needs permission to create repos in that org (org owner / sufficient role, or fine-grained token with **Administration** read-write on repositories for that org).
   - **User repos**: `POST /user/repos` — token owner becomes owner of the new repo.
2. Jenkins → **Manage Jenkins** → **Credentials** → add **Secret text**, paste the token.
3. Set credential **ID** to exactly: **`github-token-repo-create`**  
   (or change `environment { CREDENTIALS_ID = '...' }` in `Jenkinsfile.githubCreateRepo` to match.)

## Create the Jenkins job

### Option A — UI

1. **New Item** → e.g. `create-github-repo` → **Pipeline**.
2. **Pipeline** → **Pipeline script from SCM**.
3. Git: URL of **this** repo, branch `main`, credentials if private.
4. **Script Path**: `Jenkinsfile.githubCreateRepo`.
5. Save → **Build with Parameters**.

### Option B — CLI (same pattern as data-grabber)

From the **repository root** (with **`GIT_URL`** in **`.env`** — clone URL of **this** infra repo):

```bash
chmod +x scripts/create-github-repo-job.sh
./scripts/create-github-repo-job.sh
```

Optional: `JENKINS_JOB_NAME=my-bootstrap-job ./scripts/create-github-repo-job.sh`

## Parameters

| Parameter      | Meaning |
|----------------|---------|
| `OWNER_KIND`   | `organization` → `POST /orgs/{OWNER}/repos` ; `user` → `POST /user/repos` |
| `OWNER`        | Org slug when `organization` (e.g. `slothanalytics`). Ignored for `user` except leave default. |
| `REPO_NAME`    | New repo name (GitHub naming rules). |
| `DESCRIPTION`  | Optional description on GitHub. |
| `PRIVATE`      | Private repo when checked. |
| `AUTO_INIT`    | Create an initial README on the default branch. |

Successful creation returns **HTTP 201** and prints the JSON body (includes `html_url`). **422** usually means the repo already exists or the name is rejected.

## Related

- **[README.md](README.md)** — Jenkins Docker setup and CLI for this repo.
- GitHub REST API: [Create an organization repository](https://docs.github.com/en/rest/repos/repos#create-an-organization-repository), [Create a repository for the authenticated user](https://docs.github.com/en/rest/repos/repos#create-a-repository-for-the-authenticated-user).
