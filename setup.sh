#!/bin/bash
# Setup script for Presto Player PM Agent skills
# Creates symlinks from ~/.claude/skills/pm-* to this repo

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "Presto Player PM Agent — Setup"
echo "================================"
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Install it: https://cli.github.com/"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "Warning: Claude Code CLI not found. Skills will be ready when you install it."
fi

# Check gh auth
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

# Check project scopes
if ! gh api graphql -f query='{ viewer { login } }' &> /dev/null; then
    echo "Warning: GitHub CLI may be missing project scopes."
    echo "Run: gh auth refresh -h github.com -s read:project -s project"
fi

# Create skills directory if needed
mkdir -p "$SKILLS_DIR"

# Install each skill
SKILLS=(pm-daily pm-retro pm-risk pm-roadmap pm-sprint pm-triage pm-velocity)

for skill in "${SKILLS[@]}"; do
    SOURCE="$SCRIPT_DIR/skills/$skill"
    TARGET="$SKILLS_DIR/$skill"

    if [ -L "$TARGET" ]; then
        echo "  Updating symlink: $skill"
        rm "$TARGET"
    elif [ -d "$TARGET" ]; then
        echo "  Warning: $TARGET already exists (not a symlink). Backing up to ${TARGET}.bak"
        mv "$TARGET" "${TARGET}.bak"
    else
        echo "  Installing: $skill"
    fi

    ln -s "$SOURCE" "$TARGET"
done

echo ""
echo "Done! Installed ${#SKILLS[@]} skills:"
echo ""
for skill in "${SKILLS[@]}"; do
    echo "  /$skill"
done
echo ""
echo "Open Claude Code and try: /pm-daily"
