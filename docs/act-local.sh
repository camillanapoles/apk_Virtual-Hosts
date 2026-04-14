#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# act-local.sh — Local CI/CD execution helper
# BPMN Phase 4.4 – Local Execution Adaptation
#
# Wraps nektos/act to run GitHub Actions workflows locally.
# Usage:  ./docs/act-local.sh [command]
#
# Prerequisites:
#   • act installed (https://github.com/nektos/act)
#   • Docker running
#   • .secrets.local file in the project root (see docs/CI_CD.md)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_FILE="${REPO_ROOT}/.secrets.local"

# ── Helpers ───────────────────────────────────────────────────────────────────
_require_act() {
  if ! command -v act &>/dev/null; then
    echo "❌  'act' is not installed."
    echo "   Install: https://github.com/nektos/act#installation"
    exit 1
  fi
}

_require_docker() {
  if ! docker info &>/dev/null 2>&1; then
    echo "❌  Docker is not running. Start Docker and retry."
    exit 1
  fi
}

_secrets_flag() {
  if [ -f "$SECRETS_FILE" ]; then
    echo "--secret-file $SECRETS_FILE"
  else
    echo "⚠️  No .secrets.local file found — running without secrets." >&2
    echo ""
  fi
}

_usage() {
  cat <<EOF
Virtual Hosts — Local CI/CD Runner (via act)

Usage: $(basename "$0") <command>

Commands:
  build         Run CI build workflow (push event) for all flavours
  build-github  Run CI build for 'github' flavour only
  build-gplay   Run CI build for 'googleplay' flavour only
  security      Run security scan (CodeQL) workflow
  release       Simulate a release workflow (requires secrets)
  list          List all available workflow jobs
  help          Show this help message

Examples:
  ./docs/act-local.sh build
  ./docs/act-local.sh security
  ./docs/act-local.sh release
EOF
}

# ── Commands ─────────────────────────────────────────────────────────────────
cmd_build() {
  echo "▶  Running CI build (all flavours) …"
  _require_act
  _require_docker
  # shellcheck disable=SC2046
  cd "$REPO_ROOT" && act push \
    --workflows .github/workflows/ci-build.yml \
    $(_secrets_flag) \
    --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
    "$@"
}

cmd_build_github() {
  echo "▶  Running CI build (github flavour) …"
  _require_act
  _require_docker
  # shellcheck disable=SC2046
  cd "$REPO_ROOT" && act push \
    --workflows .github/workflows/ci-build.yml \
    --matrix flavor:github \
    $(_secrets_flag) \
    --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
    "$@"
}

cmd_build_gplay() {
  echo "▶  Running CI build (googleplay flavour) …"
  _require_act
  _require_docker
  # shellcheck disable=SC2046
  cd "$REPO_ROOT" && act push \
    --workflows .github/workflows/ci-build.yml \
    --matrix flavor:googleplay \
    $(_secrets_flag) \
    --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
    "$@"
}

cmd_security() {
  echo "▶  Running security scan …"
  _require_act
  _require_docker
  # CodeQL requires a GITHUB_TOKEN with security-events:write
  if [ ! -f "$SECRETS_FILE" ] || ! grep -q "GITHUB_TOKEN" "$SECRETS_FILE"; then
    echo "⚠️  GITHUB_TOKEN not found in .secrets.local."
    echo "   CodeQL result upload will be skipped (local analysis still runs)."
  fi
  # shellcheck disable=SC2046
  cd "$REPO_ROOT" && act push \
    --workflows .github/workflows/security-scan.yml \
    $(_secrets_flag) \
    --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
    "$@"
}

cmd_release() {
  echo "▶  Simulating release workflow …"
  _require_act
  _require_docker
  # act requires an event payload for tag pushes
  PAYLOAD_FILE="$(mktemp /tmp/release-event.XXXXXX.json)"
  cat > "$PAYLOAD_FILE" <<'JSON'
{
  "ref": "refs/tags/v0.0.0-local",
  "ref_name": "v0.0.0-local",
  "ref_type": "tag",
  "repository": {"full_name": "local/test"},
  "pusher": {"name": "local"}
}
JSON
  # shellcheck disable=SC2046
  cd "$REPO_ROOT" && act push \
    --workflows .github/workflows/release.yml \
    --eventpath "$PAYLOAD_FILE" \
    $(_secrets_flag) \
    --platform ubuntu-latest=catthehacker/ubuntu:act-latest \
    "$@"
  rm -f "$PAYLOAD_FILE"
}

cmd_list() {
  _require_act
  cd "$REPO_ROOT" && act --list
}

# ── Dispatch ─────────────────────────────────────────────────────────────────
COMMAND="${1:-help}"
shift 2>/dev/null || true

case "$COMMAND" in
  build)          cmd_build "$@" ;;
  build-github)   cmd_build_github "$@" ;;
  build-gplay)    cmd_build_gplay "$@" ;;
  security)       cmd_security "$@" ;;
  release)        cmd_release "$@" ;;
  list)           cmd_list ;;
  help|--help|-h) _usage ;;
  *)
    echo "❌  Unknown command: $COMMAND"
    echo ""
    _usage
    exit 1
    ;;
esac
