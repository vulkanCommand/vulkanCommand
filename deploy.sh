#!/usr/bin/env bash
set -euo pipefail

REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-$(git branch --show-current)}"
COMMIT_MESSAGE="${1:-${COMMIT_MESSAGE:-Update profile README}}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: this script must be run from inside a git repository."
  exit 1
fi

if [[ -z "$BRANCH" ]]; then
  echo "Error: detached HEAD detected. Check out a branch before deploying."
  exit 1
fi

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "Error: remote '$REMOTE' does not exist."
  exit 1
fi

echo "Deploy target: $REMOTE/$BRANCH"
echo

echo "Fetching latest remote changes..."
git fetch "$REMOTE" "$BRANCH"

echo "Rebasing local branch onto $REMOTE/$BRANCH..."
if ! git rebase --autostash "$REMOTE/$BRANCH"; then
  echo
  echo "Rebase stopped because of conflicts."
  echo "Resolve conflicts, run 'git rebase --continue', then run this script again."
  exit 1
fi

echo
echo "Current changes:"
git status --short

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  echo "No local changes to commit. Pushing rebased branch..."
  git push "$REMOTE" "$BRANCH"
  echo "Done."
  exit 0
fi

echo
echo "This script will stage all tracked and untracked changes shown above."
echo "Commit message: $COMMIT_MESSAGE"
read -r -p "Continue? [y/N] " answer

case "$answer" in
  [yY]|[yY][eE][sS])
    ;;
  *)
    echo "Cancelled. Nothing was staged, committed, or pushed."
    exit 0
    ;;
esac

git add -A

if git diff --cached --quiet; then
  echo "Nothing staged after git add. Pushing rebased branch..."
else
  git commit -m "$COMMIT_MESSAGE"
fi

echo "Pushing $BRANCH to $REMOTE..."
git push "$REMOTE" "$BRANCH"

echo "Deploy complete."
