# Version Bump Action

Automatically bump version numbers after GitHub releases for both Swift Package Manager projects and Xcode app projects.

## Key Concept: Git Tags as Source of Truth

**The latest git tag is the single source of truth for versioning.** When a release is published:

1. Action reads the latest git tag (e.g., `v4.5.0`)
2. Calculates the new version by bumping it (e.g., `v4.6.0` for minor bump)
3. **Updates ALL files** to reflect the new version, regardless of what version they currently have
   - README.md version badge
   - CLAUDE.md project metadata
   - Xcode project files (using `agvtool`)

This ensures all files in the repository stay synchronized with the correct version.

## Features

- **Git tag source of truth**: Latest tag determines current version, ensuring consistency
- **Auto-detection**: Automatically detects Swift packages vs Xcode apps
- **Smart rebasing**: Rebases development onto main before bumping
- **Version strategies**: Supports major, minor, and patch bumps
- **Multi-file updates**: Ensures all version references are updated
- **Safe force push**: Uses `--force-with-lease` to prevent accidental overwrites
- **Auto PR creation**: Creates pull request from development to main

## Usage

### Swift Package Projects

```yaml
name: Bump Version on Release

on:
  release:
    types: [published]
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  bump-version:
    runs-on: macos-latest

    steps:
      - name: Bump version
        uses: intrusive-memory/github-actions/version-bump@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          bump-type: minor  # major, minor, or patch
          project-type: swift-package
```

### Xcode App Projects

```yaml
name: Bump Version on Release

on:
  release:
    types: [published]
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  bump-version:
    runs-on: macos-latest

    steps:
      - name: Bump version
        uses: intrusive-memory/github-actions/version-bump@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          bump-type: minor
          project-type: xcode-app
```

### Auto-Detection (Recommended)

```yaml
steps:
  - name: Bump version
    uses: intrusive-memory/github-actions/version-bump@v1
    with:
      github-token: ${{ secrets.GITHUB_TOKEN }}
      # project-type defaults to 'auto'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github-token` | GitHub token for authentication | Yes | - |
| `bump-type` | Version bump type: `major`, `minor`, or `patch` | No | `minor` |
| `main-branch` | Name of the main branch | No | `main` |
| `development-branch` | Name of the development branch | No | `development` |
| `project-type` | Project type: `swift-package`, `xcode-app`, or `auto` | No | `auto` |

## Outputs

| Output | Description |
|--------|-------------|
| `old-version` | Previous version before bump (from git tag) |
| `new-version` | New version after bump |
| `pr-url` | URL of the created pull request |

## How It Works

1. Checks out main branch and ensures development branch exists
2. Checks out development branch
3. Rebases development onto main (prevents divergence)
4. Detects project type (if auto)
5. **Reads latest git tag as source of truth**
6. Calculates new version based on bump type
7. **Updates ALL version references** in the repository:
   - **Swift packages**: README.md, CLAUDE.md
   - **Xcode apps**: Project files via `agvtool`, README.md, CLAUDE.md
8. Commits changes
9. Force pushes to development (safe with `--force-with-lease`)
10. Creates pull request from development to main

## Version Detection & Updates

### Swift Packages

**Reads from:** Latest git tag (e.g., `v4.5.0` or `4.5.0`)

**Updates:**
- README.md version badge: `![Version](https://img.shields.io/badge/Version-X.Y.Z-blue)`
- README.md installation: `from: "X.Y.Z"`
- README.md version selection: `version: **X.Y.Z**`
- CLAUDE.md metadata: `**Version**: X.Y.Z`

### Xcode Apps

**Reads from:** Latest git tag

**Updates:**
- Xcode project marketing version (via `agvtool new-marketing-version`)
- README.md version badge (if present)
- CLAUDE.md metadata (if present)

## Requirements

- **All projects**: Must have at least one git tag (e.g., `v1.0.0`)
- **Swift packages**: `Package.swift` file present
- **Xcode apps**: `.xcodeproj` file present
- Branch protection should allow GitHub Actions to push

## Example Workflow

```
Release v4.5.0 published
  ↓
Action reads tag: v4.5.0
  ↓
Calculates new version: v4.6.0 (minor bump)
  ↓
Updates all files:
  - README.md: 4.5.0 → 4.6.0
  - CLAUDE.md: 4.5.0 → 4.6.0
  - (Xcode: project files)
  ↓
Commits: "chore: Bump version to 4.6.0 after release v4.5.0"
  ↓
Creates PR: development → main
```
