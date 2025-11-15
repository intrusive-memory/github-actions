#!/bin/bash
set -e

# Get the latest git tag (source of truth for versioning)
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -z "$LATEST_TAG" ]; then
  echo "Error: No git tags found. Please create an initial release tag (e.g., v1.0.0)"
  exit 1
fi

# Strip 'v' prefix if present (handles both v1.2.3 and 1.2.3)
CURRENT_VERSION=$(echo "$LATEST_TAG" | sed 's/^v//')

echo "Latest git tag: $LATEST_TAG"
echo "Current version: $CURRENT_VERSION"

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

echo "New version: $NEW_VERSION"

# Update README.md - replace ANY existing version with the new version
if [ -f "README.md" ]; then
  # Update version badge (handles any existing version)
  sed -i.bak -E "s/Version-[0-9]+\.[0-9]+\.[0-9]+-blue/Version-${NEW_VERSION}-blue/g" README.md

  # Update installation instructions (from: "X.Y.Z") - handles any existing version
  sed -i.bak -E "s/from: \"[0-9]+\.[0-9]+\.[0-9]+\"/from: \"${NEW_VERSION}\"/g" README.md

  # Update version selection instruction (Select version: **X.Y.Z** or later)
  sed -i.bak -E "s/version: \*\*[0-9]+\.[0-9]+\.[0-9]+\*\*/version: **${NEW_VERSION}**/g" README.md

  rm -f README.md.bak
  echo "Updated README.md to version $NEW_VERSION"
fi

# Update CLAUDE.md if it exists - replace ANY existing version
if [ -f "CLAUDE.md" ]; then
  # Update version in Project Metadata section (handles any existing version)
  sed -i.bak -E "s/Version\*\*: [0-9]+\.[0-9]+\.[0-9]+/Version**: ${NEW_VERSION}/g" CLAUDE.md
  rm -f CLAUDE.md.bak
  echo "Updated CLAUDE.md to version $NEW_VERSION"
fi

# Output versions for GitHub Actions
echo "old-version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
echo "new-version=$NEW_VERSION" >> $GITHUB_OUTPUT
