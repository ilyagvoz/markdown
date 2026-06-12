#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE="${REMOTE:-origin}"
TARGET_BRANCH="${TARGET_BRANCH:-}"
TARGET_COMMIT="${TARGET_COMMIT:-}"
RUN_TESTS="${RUN_TESTS:-0}"
OPEN_AFTER_INSTALL="${OPEN_AFTER_INSTALL:-0}"
QUIT_RUNNING_APP="${QUIT_RUNNING_APP:-1}"
KEEP_WORKTREE="${KEEP_WORKTREE:-0}"

WORKTREE_DIR=""

usage() {
  cat <<'USAGE'
Usage: scripts/update-to-latest-commit.sh [options]

Fetch the latest commit from GitHub, rebuild that commit from source in a
temporary worktree, and install it to /Applications/Markdown.app.

By default, the script uses the remote's default branch. For this repository,
that is normally origin/main.

Options:
  --remote NAME          Git remote to fetch from. Defaults to origin.
  --branch NAME          Build the latest commit from this remote branch.
  --commit SHA           Build a specific commit instead of a branch head.
  --run-tests            Run ./scripts/test-macos.sh before installing.
  --open                 Open /Applications/Markdown.app after installation.
  --keep-worktree        Keep the temporary worktree for inspection.
  -h, --help             Show this help.

Environment:
  REMOTE                 Same as --remote.
  TARGET_BRANCH          Same as --branch.
  TARGET_COMMIT          Same as --commit.
  RUN_TESTS=1            Same as --run-tests.
  OPEN_AFTER_INSTALL=1   Same as --open.
  QUIT_RUNNING_APP=0     Do not ask a running Markdown app to quit first.
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$WORKTREE_DIR" && "$KEEP_WORKTREE" != "1" ]]; then
    git -C "$ROOT_DIR" worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || rm -rf "$WORKTREE_DIR"
  elif [[ -n "$WORKTREE_DIR" ]]; then
    echo "Kept worktree: $WORKTREE_DIR"
  fi
}
trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote)
      [[ $# -ge 2 ]] || fail "--remote requires a value"
      REMOTE="$2"
      shift 2
      ;;
    --branch)
      [[ $# -ge 2 ]] || fail "--branch requires a value"
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --commit)
      [[ $# -ge 2 ]] || fail "--commit requires a value"
      TARGET_COMMIT="$2"
      shift 2
      ;;
    --run-tests)
      RUN_TESTS=1
      shift
      ;;
    --open)
      OPEN_AFTER_INSTALL=1
      shift
      ;;
    --keep-worktree)
      KEEP_WORKTREE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

command -v git >/dev/null 2>&1 || fail "git is required"

git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "$ROOT_DIR is not a git worktree"
git -C "$ROOT_DIR" remote get-url "$REMOTE" >/dev/null 2>&1 || fail "remote '$REMOTE' does not exist"

if [[ -n "$TARGET_COMMIT" && -n "$TARGET_BRANCH" ]]; then
  fail "use either --commit or --branch, not both"
fi

if [[ -z "$TARGET_COMMIT" ]]; then
  if [[ -z "$TARGET_BRANCH" ]]; then
    echo "Resolving default branch from $REMOTE..."
    TARGET_BRANCH="$(
      git -C "$ROOT_DIR" ls-remote --symref "$REMOTE" HEAD |
        awk '$1 == "ref:" { sub("^refs/heads/", "", $2); print $2; exit }'
    )"
  fi

  [[ -n "$TARGET_BRANCH" ]] || fail "could not resolve the default branch for $REMOTE"
  git -C "$ROOT_DIR" check-ref-format --branch "$TARGET_BRANCH" >/dev/null || fail "invalid branch name: $TARGET_BRANCH"
  git -C "$ROOT_DIR" ls-remote --exit-code --heads "$REMOTE" "$TARGET_BRANCH" >/dev/null 2>&1 || fail "branch '$TARGET_BRANCH' was not found on $REMOTE"

  echo "Fetching latest $REMOTE/$TARGET_BRANCH..."
  git -C "$ROOT_DIR" fetch --prune "$REMOTE" "+refs/heads/$TARGET_BRANCH:refs/remotes/$REMOTE/$TARGET_BRANCH"
  TARGET_COMMIT="$(git -C "$ROOT_DIR" rev-parse "refs/remotes/$REMOTE/$TARGET_BRANCH^{commit}")"
else
  echo "Fetching $TARGET_COMMIT from $REMOTE..."
  git -C "$ROOT_DIR" fetch --prune "$REMOTE" "$TARGET_COMMIT"
  TARGET_COMMIT="$(git -C "$ROOT_DIR" rev-parse "FETCH_HEAD^{commit}")"
fi

SHORT_COMMIT="$(git -C "$ROOT_DIR" rev-parse --short "$TARGET_COMMIT")"

WORKTREE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markdown-update.XXXXXX")"
rm -rf "$WORKTREE_DIR"

echo "Checking out $SHORT_COMMIT into a temporary worktree..."
git -C "$ROOT_DIR" worktree add --detach "$WORKTREE_DIR" "$TARGET_COMMIT" >/dev/null

if [[ "$QUIT_RUNNING_APP" == "1" ]] && pgrep -x Markdown >/dev/null 2>&1; then
  echo "Asking running Markdown app to quit..."
  osascript -e 'tell application "Markdown" to quit' >/dev/null 2>&1 || true
  for _ in {1..20}; do
    pgrep -x Markdown >/dev/null 2>&1 || break
    sleep 0.25
  done
  pgrep -x Markdown >/dev/null 2>&1 && fail "Markdown is still running. Quit it and rerun the update script."
fi

if [[ "$RUN_TESTS" == "1" ]]; then
  echo "Running tests for $SHORT_COMMIT..."
  "$WORKTREE_DIR/scripts/test-macos.sh"
fi

echo "Building and installing $SHORT_COMMIT..."
"$WORKTREE_DIR/scripts/install-macos-app.sh"

if [[ "$OPEN_AFTER_INSTALL" == "1" ]]; then
  open "/Applications/Markdown.app"
fi

if [[ -n "$TARGET_BRANCH" ]]; then
  echo "Installed Markdown from $REMOTE/$TARGET_BRANCH at $SHORT_COMMIT."
else
  echo "Installed Markdown from $SHORT_COMMIT."
fi
