#!/bin/bash

set -e

ISSUE_URL="$1"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <github-issue-url>"
    exit 1
fi

if [[ ! "$ISSUE_URL" =~ ^https://github\.com/([^/]+)/([^/]+)/issues/([0-9]+)$ ]]; then
    echo "Erreur: URL d'issue GitHub invalide"
    exit 1
fi

ISSUE_NUMBER="${BASH_REMATCH[3]}"

ISSUE_TITLE=$(gh issue view "$ISSUE_URL" --json title --jq '.title')

if [ -z "$ISSUE_TITLE" ]; then
    echo "Erreur: Impossible de récupérer les informations de l'issue"
    exit 1
fi

BRANCH_NAME=$(echo "issue-$ISSUE_NUMBER-$ISSUE_TITLE" | \
    sed 's/[^a-zA-Z0-9-]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-\|-$//g' | \
    tr '[:upper:]' '[:lower:]' | \
    cut -c1-50)

PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_PATH="../worktree/$PROJECT_NAME/$BRANCH_NAME"

echo "Création du worktree pour: $ISSUE_TITLE"
echo "Branche: $BRANCH_NAME"

mkdir -p "../worktree/$PROJECT_NAME"

if [ ! -d ".git" ]; then
    echo "Erreur: Ce répertoire n'est pas un dépôt git"
    exit 1
fi

git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"

echo "✅ Worktree créé: $WORKTREE_PATH"
