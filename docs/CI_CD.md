# CI/CD Pipeline — Virtual Hosts

This document describes the Continuous Integration and Continuous Delivery
(CI/CD) pipeline implemented for the **Virtual Hosts** Android project.
The pipeline was designed following the BPMN Blueprint Pattern for codebase
exploration and safe action selection (see [`BLUEPRINT.md`](BLUEPRINT.md)).

---

## Workflows Overview

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| **CI — Build & Test** | `ci-build.yml` | Push / PR to `main` | Compile + unit test all flavours |
| **Security Scan** | `security-scan.yml` | Push / PR / weekly | CodeQL + dependency review |
| **Release** | `release.yml` | Tag `v*` push | Build signed APK + GitHub Release |

---

## Workflow Details

### 1. CI — Build & Test (`ci-build.yml`)

**BPMN Phase:** 4 — Transformation (staging pipeline)

```
push / pull_request
        │
        ▼
  [checkout] → [setup-java 17] → [setup-gradle]
        │
        ▼ (parallel matrix: github | googleplay)
  [unit tests] → [assemble debug APK] → [upload artifact]
```

**Flavour matrix:**

| Flavour | Google Play services | Distribution |
|---------|---------------------|--------------|
| `github` | ❌ None | GitHub Releases / F-Droid |
| `googleplay` | ✅ Firebase Analytics, Billing | Google Play Store |

**Artifacts produced:** `apk-<flavor>-debug-<sha>` (retained 14 days)

---

### 2. Security Scan (`security-scan.yml`)

**BPMN Phase:** 2 — Analysis + 5.3 — Security Scan of Pipeline

```
push / pull_request / weekly cron
        │
        ├─▶ Job: codeql
        │       [checkout] → [setup-java] → [setup-gradle]
        │       → [codeql init (security-and-quality)]
        │       → [autobuild] → [codeql analyze]
        │       → [upload SARIF to Security tab]
        │
        └─▶ Job: dependency-review  (PR only)
                [checkout] → [dependency-review]
                → blocks PR if HIGH/CRITICAL CVE or non-GPL-compatible licence
```

Results appear in the **Security → Code scanning alerts** tab.

---

### 3. Release (`release.yml`)

**BPMN Phase:** 4 — Transformation (production pipeline)

```
git tag v*
        │
        ▼
  [checkout (full history)] → [setup-java 17] → [setup-gradle]
        │
        ▼
  [decode keystore] (optional, requires secrets)
        │
        ▼
  [assembleGithubRelease] (signed if keystore present)
        │
        ▼
  [upload artifact] → [generate changelog] → [create GitHub Release]
```

**Required secrets for signing** (optional — unsigned APK is produced otherwise):

| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` keystore file |
| `KEY_ALIAS` | Signing key alias |
| `KEY_PASSWORD` | Signing key password |
| `STORE_PASSWORD` | Keystore password |

To set secrets: **Settings → Secrets and variables → Actions → New repository secret**

**To create a release:**
```bash
git tag v2.2.4
git push origin v2.2.4
```

---

## Actions Used & Safety Scores

All actions are **SHA-pinned** to prevent supply-chain attacks.

| Action | Version | SHA Pin | Safety Score | Publisher |
|--------|---------|---------|-------------|-----------|
| `actions/checkout` | v4.2.2 | `34e11488` | 3.0 ✅ | GitHub Official |
| `actions/setup-java` | v4 | `c1e32368` | 3.0 ✅ | GitHub Official |
| `gradle/actions/setup-gradle` | v4 | `ed408507` | 2.8 ✅ | Gradle Official |
| `actions/upload-artifact` | v4.6.2 | `ea165f8d` | 3.0 ✅ | GitHub Official |
| `actions/cache` | v4 | `00578528` | 3.0 ✅ | GitHub Official |
| `github/codeql-action` | v3 | `5c8a8a64` | 3.0 ✅ | GitHub Official |
| `actions/dependency-review-action` | v4.9.0 | `2031cfc0` | 3.0 ✅ | GitHub Official |
| `softprops/action-gh-release` | v2.6.2 | `3bb12739` | 2.2 ✅ | Community >5K★ |

**Scoring criteria (BPMN Decision Table):**
- Publisher weight: 30%
- SHA pinning weight: 20%
- Maintenance activity weight: 20%
- Known CVEs weight: 20%
- Compatibility weight: 10%
- **Threshold:** score ≥ 2.0 required for staging; ≥ 2.5 for production

---

## Local Execution

Run workflows locally using [**nektos/act**](https://github.com/nektos/act):

```bash
# Install act (macOS)
brew install act

# Install act (Linux)
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# List available workflows
act --list

# Run CI build (push event)
act push --secret-file .secrets.local

# Run security scan
act schedule --secret-file .secrets.local

# Run with a specific flavour matrix value
act push -e .github/event-push.json --secret-file .secrets.local
```

**Create `.secrets.local`** (never commit this file):
```ini
GITHUB_TOKEN=ghp_your_token_here
KEYSTORE_BASE64=
KEY_ALIAS=
KEY_PASSWORD=
STORE_PASSWORD=
```

See [`act-local.sh`](act-local.sh) for a convenience wrapper script.

---

## Automated Dependency Updates

[Dependabot](../.github/dependabot.yml) opens weekly PRs to update:
- **GitHub Actions** — grouped into a single PR
- **Gradle dependencies** — minor/patch updates grouped

Every Dependabot PR is automatically scanned by the **Security Scan**
workflow before merging.

---

## Permissions Model

All workflows use **minimal GITHUB_TOKEN permissions** per the principle of
least privilege:

| Workflow | `contents` | `security-events` | `actions` |
|----------|-----------|-------------------|-----------|
| ci-build | `read` | — | — |
| security-scan | `read` | `write` | `read` |
| release | `write` | — | — |

---

## Troubleshooting

### Build fails with "SDK location not found"

The Android SDK is automatically installed by the GitHub-hosted `ubuntu-latest`
runner. If you are running locally with `act`, set:
```bash
export ANDROID_HOME=$HOME/Android/Sdk
```
or pass `--env ANDROID_HOME=/path/to/sdk` to `act`.

### CodeQL autobuild fails

CodeQL's autobuild tries to detect the build system automatically. If it
fails, replace the `autobuild` step with an explicit build command:
```yaml
- run: ./gradlew assembleGithubDebug --no-daemon
```

### Release APK not found

Ensure the `assembleGithubRelease` Gradle task succeeds locally before
pushing a tag. The `find` command in the workflow will exit non-zero if no
APK is produced, which provides a clear error message.
