# BPMN Blueprint — Codebase Exploration & Safe Action Selection

> **Status:** Validated ✅ — Applied to `apk_Virtual-Hosts` (Android/Java)  
> **Version:** 1.0  
> **Scope:** Generic · Ecosystem-agnostic · Applicable to any software project

---

## Overview

This blueprint defines a **6-phase BPMN workflow** for systematically
exploring a codebase and generating a secure, up-to-date, compatible
CI/CD pipeline that can run in staging or production-local mode.

The blueprint is **agnostic**: it applies equally to Android, iOS, Web,
Backend, Infrastructure, ML, Embedded, Desktop, CLI, and Library projects.

---

## BPMN Flow Diagram (text notation)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│  POOL: CODEBASE EXPLORATION & ACTION PIPELINE                                                       │
│                                                                                                     │
│  ●START──▶[PHASE 1: DISCOVERY]──▶◇G1──▶[PHASE 2: ANALYSIS]──▶◇G2──▶[PHASE 3: SELECTION]──▶◇G3──▶ │
│                                                                                                     │
│  ──▶[PHASE 4: TRANSFORMATION]──▶◇G4──▶[PHASE 5: VALIDATION]──▶◇G5──▶[PHASE 6: OPTIMIZATION]──▶●END│
│                                          ▲                │                                         │
│                                          └─── LOOP ───────┘ (on failure)                           │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Legend:** `●` = event · `[ ]` = sub-process · `◇` = gateway · `G` = gate

---

## Phase 1 — DISCOVERY (Exploração Inicial)

**BPMN type:** Sub-Process (Collapsed)

| ID | Task | BPMN Type | Description |
|----|------|-----------|-------------|
| 1.1 | Inventory Scan | Service Task | List ALL files, directories, languages, frameworks, entry points |
| 1.2 | CI/CD Detection | Service Task | Find existing pipelines: `.github/workflows/`, `Jenkinsfile`, `.travis.yml`, `.circleci/`, `.gitlab-ci.yml`, `azure-pipelines.yml`, `Makefile`, `Taskfile`, `docker-compose.yml` |
| 1.3 | Dependency Mapping | Service Task | Extract all dependencies: `build.gradle`, `package.json`, `pom.xml`, `Gemfile`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pubspec.yaml`, `*.csproj`, `composer.json`, etc. |
| 1.4 | Ecosystem Classification | User Task | Classify: language · framework · build system · package manager · runtime · distribution targets |
| 1.5 | Security Baseline | Service Task | Find exposed credentials, API keys, secrets, tokens; verify `.gitignore` coverage |

### Gate G1 (Exclusive Gateway)

| Condition | Route |
|-----------|-------|
| Inventory complete | → Phase 2 |
| Repository empty or inaccessible | → END (Error Event) |

---

## Phase 2 — ANALYSIS (Análise de Riscos e Compatibilidade)

**BPMN type:** Sub-Process (Expanded — Parallel)

| ID | Task | BPMN Type | Description |
|----|------|-----------|-------------|
| 2.1 | Dependency Vulnerability Scan | Service Task | Query GitHub Advisory DB, OSV, NVD/CVE databases for each dependency |
| 2.2 | Dependency Freshness Check | Service Task | Compare current vs. latest stable version for each dependency |
| 2.3 | Action Safety Audit | Service Task | For each existing or candidate action: publisher, maintenance, CVEs, SHA pinning |
| 2.4 | Compatibility Matrix | Service Task | Verify language version × SDK × build tool × runtime × OS compatibility |
| 2.5 | License Compliance | Service Task | Verify all dependency and action licences are compatible with the project licence |
| 2.6 | Build System Analysis | Service Task | Analyse plugins, configurations, targets, flavours/variants, environments |

### Gate G2 (Parallel Join — all tasks must complete)

| Condition | Route |
|-----------|-------|
| All sub-tasks complete | → Phase 3 (with consolidated report) |
| Critical vulnerabilities found | → Phase 3 (with CVE flags for attention) |

---

## Phase 3 — SELECTION (Seleção de Actions Seguras)

**BPMN type:** Sub-Process with Decision Tables

| ID | Task | BPMN Type | Description |
|----|------|-----------|-------------|
| 3.1 | Action Candidate Generation | Service Task | Generate candidate action list per detected ecosystem and pipeline category |
| 3.2 | Safety Scoring | Business Rule Task | Apply Decision Table (see below) |
| 3.3 | Threshold Gate | Exclusive Gateway | Route by score |
| 3.4 | Action Pinning | Service Task | Fix every approved action to a specific commit SHA |
| 3.5 | Permissions Scoping | Service Task | Define minimum GITHUB_TOKEN scopes per action |

### Decision Table — Action Safety Score

| Criterion | Weight | Score 0 — Reject | Score 1 — Low | Score 2 — Medium | Score 3 — High |
|-----------|--------|------------------|--------------|-----------------|---------------|
| **Publisher** | 30% | Unknown | Community (<100 ★) | Community (>1K ★) | Official (actions/\*, github/\*) |
| **SHA Pinning** | 20% | Mutable tag (latest) | Major tag (v3) | Full tag (v3.1.2) | Commit SHA hash |
| **Maintenance** | 20% | Abandoned (>2y) | Low (>1y) | Active (<6m) | Very active (<1m) |
| **Vulnerabilities** | 20% | Open critical CVE | Open medium CVE | Recently fixed CVE | No CVEs |
| **Compatibility** | 10% | Incompatible | Partial | Compatible with adjustments | Fully compatible |

**Composite score** = Σ(criterion\_score × weight) · max = 3.0

### Score-to-Environment Threshold

| Environment | Min Score | Additional Requirements |
|-------------|-----------|------------------------|
| Development | ≥ 1.5 | None |
| Staging | ≥ 2.0 | SHA pinning mandatory |
| Production | ≥ 2.5 | SHA pinning + verified publisher + no open CVEs |
| Critical / Financial | ≥ 2.8 | All above + audit trail + approval gates |

### Gate G3 (Inclusive Gateway)

| Condition | Route |
|-----------|-------|
| ≥1 approved action per required category | → Phase 4 |
| No action passes threshold for a required category | → LOOP to 3.1 (relaxed criteria or alternative search) |

---

## Phase 4 — TRANSFORMATION (Geração de Pipeline Staging/Local)

**BPMN type:** Sub-Process (Sequential)

| ID | Task | BPMN Type | Description |
|----|------|-----------|-------------|
| 4.1 | Workflow Template Generation | Service Task | Generate workflow YAML file(s) adapted to the detected ecosystem |
| 4.2 | Environment Configuration | Service Task | Configure `runs-on`, `env`, `secrets`, `matrix` strategies |
| 4.3 | Staging Pipeline Assembly | Service Task | Assemble: checkout → setup → cache → build → test → lint → security scan → artifact |
| 4.4 | Local Execution Adaptation | Service Task | Adapt for local execution: `act` (nektos/act), `docker compose`, equivalent bash scripts |
| 4.5 | Secret Management | Service Task | Configure secret handling: `.env.local`, `--secret-file`, environment-specific configs |
| 4.6 | Documentation Generation | Service Task | Generate: CI/CD README, contribution guide, troubleshooting |

### Gate G4 (Exclusive Gateway)

| Condition | Route |
|-----------|-------|
| Pipeline generated successfully | → Phase 5 |
| Incompatibility detected | → LOOP to Phase 3 |

---

## Phase 5 — VALIDATION (Teste e Verificação)

**BPMN type:** Sub-Process (Parallel)

| ID | Task | BPMN Type | Description |
|----|------|-----------|-------------|
| 5.1 | Syntax Validation | Service Task | Validate YAML syntax of all generated workflow files |
| 5.2 | Dry Run | Service Task | Execute pipeline in dry-run mode (local via `act` or `--dry-run`) |
| 5.3 | Security Scan of Pipeline | Service Task | Scan the pipeline itself for supply-chain attacks, injection risks, over-privileged tokens |
| 5.4 | Dependency Resolution Test | Service Task | Verify all dependencies resolve correctly in the target environment |
| 5.5 | Idempotency Test | Service Task | Run pipeline multiple times; verify consistent results |
| 5.6 | Rollback Test | Service Task | Verify revert to previous state is possible without data loss |

### Gate G5 (Exclusive Gateway)

| Condition | Route |
|-----------|-------|
| All tests pass | → Phase 6 |
| Any critical test fails | → LOOP to Phase 4 (with corrections) |
| Non-critical test fails | → Phase 6 (with warnings documented) |

---

## Phase 6 — OPTIMIZATION (Melhoria Contínua)

**BPMN type:** Sub-Process (Iterative — Timer-triggered)

| ID | Task | BPMN Type | Description |
|----|------|-----------|-------------|
| 6.1 | Performance Profiling | Service Task | Measure execution time per pipeline step |
| 6.2 | Cache Optimization | Service Task | Optimise cache strategies: dependencies, build artifacts, Docker layers |
| 6.3 | Parallelization | Service Task | Identify parallelisable tasks; configure parallel `jobs` |
| 6.4 | Cost Analysis | Service Task | Estimate CI execution costs (runner minutes, storage, compute) |
| 6.5 | Blueprint Generalization | User Task | Abstract ecosystem-specific values into variables/templates |
| 6.6 | Final Report | Service Task | Generate report: metrics, residual risks, recommendations |

### Continuous Improvement Loop

```
[Timer: Weekly/Monthly]
    │
    ├──▶ [Check Action Updates] ──▶ [Re-score Updated Actions]
    │                                       │
    ├──▶ [Check New CVEs] ─────────▶ [Update Pinned SHAs if safe]
    │                                       │
    └──▶ [Check Ecosystem Changes] ─▶ [Update Compatibility Matrix]
                                            │
                                    [Generate Delta Report]
                                            │
                                    [Human Review Gate]
                                            │
                                    [Apply Updates] ──▶ [END LOOP]
```

---

## Universal Action Mapping Table

| Category | Android/JVM | iOS/macOS | Node.js | Python | Go | Rust | .NET | Docker/K8s |
|----------|-------------|-----------|---------|--------|----|------|------|-----------|
| **Checkout** | `actions/checkout` | `actions/checkout` | `actions/checkout` | `actions/checkout` | `actions/checkout` | `actions/checkout` | `actions/checkout` | `actions/checkout` |
| **Runtime Setup** | `actions/setup-java` | Xcode (built-in) | `actions/setup-node` | `actions/setup-python` | `actions/setup-go` | `dtolnay/rust-toolchain` | `actions/setup-dotnet` | `docker/setup-buildx-action` |
| **Build** | `gradle/actions/setup-gradle` | `xcode-build` | `npm ci` / `yarn install` | `pip install` | `go build` | `cargo build` | `dotnet build` | `docker/build-push-action` |
| **Test** | Gradle `test` task | `xcodebuild test` | `npm test` | `pytest` | `go test ./...` | `cargo test` | `dotnet test` | Container healthcheck |
| **Lint** | Detekt / KtLint / Checkstyle | SwiftLint | ESLint / Prettier | Ruff / pylint / flake8 | golangci-lint | Clippy | `dotnet format` | Hadolint / trivy |
| **Security** | `github/codeql-action` | `github/codeql-action` | CodeQL + `npm audit` | CodeQL + Safety | CodeQL + Gosec | CodeQL + `cargo audit` | `github/codeql-action` | Trivy + Grype |
| **Cache** | `setup-gradle` (auto) | CocoaPods cache | `actions/cache` (npm) | `actions/cache` (pip) | `actions/cache` (go) | `actions/cache` (cargo) | `actions/cache` (nuget) | Docker layer cache |
| **Artifact** | `actions/upload-artifact` (APK) | `actions/upload-artifact` (IPA) | `actions/upload-artifact` | `actions/upload-artifact` | `actions/upload-artifact` | `actions/upload-artifact` | `actions/upload-artifact` | `docker/push` / ghcr.io |
| **Release** | `softprops/action-gh-release` | `softprops/action-gh-release` | `npm publish` | `pypa/gh-action-pypi-publish` | GoReleaser | `cargo publish` | `nuget push` | `docker/metadata-action` |

---

## Ecosystem Variables Template

```yaml
# Fill this template for any project to parametrise the blueprint.
ecosystem:
  type: android|ios|web|backend|infra|library|cli|desktop|embedded|ml
  language: java|kotlin|swift|typescript|python|go|rust|csharp|ruby|php|dart
  build_tool: gradle|maven|npm|yarn|pip|cargo|go|dotnet|cmake|make|bazel|buck
  package_manager: maven|npm|pip|cargo|nuget|rubygems|pub|cocoapods|spm|brew
  runtime: jvm|node|python|go|dotnet|native|wasm|docker
  test_framework: junit|pytest|jest|mocha|rspec|xunit|xctest|gotest|cargo-test
  lint_tool: checkstyle|eslint|pylint|golint|clippy|swiftlint|ktlint|detekt
  security_scanner: codeql|snyk|trivy|bandit|gosec|cargo-audit|npm-audit|safety
  artifact_type: apk|ipa|jar|war|docker-image|binary|npm-package|pypi-package|gem|crate|nuget
  deploy_target: playstore|appstore|npm-registry|pypi|docker-hub|s3|gcs|azure|k8s|lambda|vercel|netlify|gh-pages
```

---

## Success Metrics

| Metric | Target | How to Measure |
|--------|--------|---------------|
| Detection Coverage | 100% of dependencies mapped | count(detected) / count(actual) |
| Average Action Safety Score | ≥ 2.5 | Weighted average of all selected actions |
| Pipeline Execution Time | < 15 min | Wall-clock time of longest job |
| False-positive Rate | < 10% | Dismissed alerts / total alerts |
| Reproducibility | 100% | Same input → same output across runs |
| Ecosystem Portability | ≥ 3 ecosystems tested | Ecosystems where blueprint was applied successfully |

---

## Validation — Application to `apk_Virtual-Hosts`

| Criterion | Status | Notes |
|-----------|--------|-------|
| Blueprint applied to project | ✅ | All 6 phases executed |
| Complete dependency detection | ✅ | 17/17 mapped + 1 vendored (xbill DNS) |
| Security risk identification | ✅ | 3 risks: google-services.json, Baidu ID, stale libs |
| Actions with score ≥ 2.0 selected | ✅ | 8 actions, all from official or mature publishers |
| Staging/local pipeline generated | ✅ | 3 workflows: build, security, release |
| SHA pinning applied | ✅ | Every action pinned to commit hash |
| Minimal permissions applied | ✅ | Per-workflow, per-job permission scopes |
| Dependabot configured | ✅ | Weekly updates for Actions + Gradle |
| CODEOWNERS configured | ✅ | Human gates on CI/security files |
| Security policy published | ✅ | `SECURITY.md` with disclosure process |
| Local execution documented | ✅ | `act-local.sh` + `docs/CI_CD.md` |
| Ecosystem-agnostic | ✅ | Universal mapping table + variable template |

---

## Changelog

| Version | Date | Notes |
|---------|------|-------|
| 1.0 | 2026-04-14 | Initial version — validated on Android/Java project |
