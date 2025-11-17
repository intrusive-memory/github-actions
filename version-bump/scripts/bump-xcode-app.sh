#!/bin/bash
set -e

# ========================================================================
# VERSION BUMP SCRIPT FOR XCODE APPS
# ========================================================================
# This script reads the git tag AFTER development has been rebased onto main.
# Main branch is the source of commit truth, so the tag comes from main's
# commit history.
# ========================================================================

echo "Reading version from git tags..."

# Get the latest git tag (source of truth for versioning)
# This is read AFTER the rebase, so we're reading from main's history
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
  echo "Error: No git tags found. Please create an initial release tag (e.g., v1.0.0)"
  exit 1
fi

# Strip 'v' prefix if present (handles both v1.2.3 and 1.2.3)
CURRENT_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

echo "Latest git tag (from main): $LATEST_TAG"
echo "Current version (from tag): $CURRENT_VERSION"

# Detect version format: simple integer (9) vs semantic (9.0.0)
if [[ "$CURRENT_VERSION" =~ ^[0-9]+$ ]]; then
  # Simple integer versioning (v9 → v10)
  # Always increment by 1 for simple versioning
  echo "Detected simple integer versioning"
  NEW_VERSION="$((CURRENT_VERSION + 1))"
  echo "Simple increment: $CURRENT_VERSION → $NEW_VERSION"
else
  # Semantic versioning (v9.0.0 → v9.1.0)
  echo "Detected semantic versioning"
  # Split version into components
  MAJOR=$(echo $CURRENT_VERSION | cut -d. -f1)
  MINOR=$(echo $CURRENT_VERSION | cut -d. -f2)
  PATCH=$(echo $CURRENT_VERSION | cut -d. -f3)

  # Calculate new version based on bump type
  case "$BUMP_TYPE" in
    major)
      NEW_VERSION="$((MAJOR + 1)).0.0"
      ;;
    minor)
      NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
      ;;
    patch)
      NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
      ;;
    *)
      echo "Error: Invalid bump type: $BUMP_TYPE"
      exit 1
      ;;
  esac
fi

echo "New version: $NEW_VERSION"

# Find the Xcode project
PROJECT_FILE=$(find . -maxdepth 2 -name "*.xcodeproj" -print -quit)

if [ -z "$PROJECT_FILE" ]; then
  echo "Error: No Xcode project found"
  exit 1
fi

# Navigate to project directory for agvtool
ORIGINAL_DIR=$(pwd)
PROJECT_DIR=$(dirname "$PROJECT_FILE")
cd "$PROJECT_DIR"

# Update version using agvtool (sets to NEW version regardless of what's currently there)
echo "Setting Xcode project version to $NEW_VERSION"
agvtool new-marketing-version "$NEW_VERSION"

# Return to original directory
cd "$ORIGINAL_DIR"

# Update README.md if it exists - replace ANY existing version
if [ -f "README.md" ]; then
  # Update version badge (handles any existing version)
  sed -i.bak -E "s/Version-[0-9]+\.[0-9]+\.[0-9]+-blue/Version-${NEW_VERSION}-blue/g" README.md
  rm -f README.md.bak
  echo "Updated README.md to version $NEW_VERSION"
fi

# Update CLAUDE.md if it exists - replace ANY existing version
if [ -f "CLAUDE.md" ]; then
  sed -i.bak -E "s/Version\*\*: [0-9]+\.[0-9]+\.[0-9]+/Version**: ${NEW_VERSION}/g" CLAUDE.md
  rm -f CLAUDE.md.bak
  echo "Updated CLAUDE.md to version $NEW_VERSION"
fi

# Output versions for GitHub Actions
echo "old-version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
echo "new-version=$NEW_VERSION" >> $GITHUB_OUTPUT
