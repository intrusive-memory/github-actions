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

**Main branch is the source of commit truth.** The action ensures all version bumps are based on main's commit history:

### Workflow Diagram

```
                    ┌─────────────────────────────────┐
                    │  Release v4.5.0 Published       │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  1. Checkout main branch        │
                    │     (SOURCE OF TRUTH)           │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  2. Ensure development exists   │
                    │     (create from main if needed)│
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  3. Checkout development        │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  4. REBASE development onto     │
                    │     origin/main                 │
                    │     ⚠️  BEFORE version ops      │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┴──────────────────┐
                    │  Now development is based on    │
                    │  main's commit history          │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  5. Read latest git tag         │
                    │     v4.5.0                      │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  6. Calculate new version       │
                    │     4.5.0 + minor = 4.6.0       │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  7. Update ALL version files    │
                    │     README.md: 4.5.0 → 4.6.0    │
                    │     CLAUDE.md: 4.5.0 → 4.6.0    │
                    │     (Xcode: project.pbxproj)    │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  8. Commit version bump         │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  9. Force push to development   │
                    │     (--force-with-lease)        │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │  10. Create PR                  │
                    │      development → main         │
                    └─────────────────────────────────┘
```

### Step-by-Step Flow

1. **Checks out main branch** (establishes source of truth)
2. Ensures development branch exists (creates from main if needed)
3. Checks out development branch
4. **Rebases development onto main** (ensures development is based on latest main commits)
   - This happens BEFORE any version operations
   - Main's commit history becomes the base for development
5. Detects project type (if auto)
6. **Reads latest git tag** (from rebased development, which is now based on main)
7. Calculates new version based on bump type
8. **Updates ALL version references** in the repository:
   - **Swift packages**: README.md, CLAUDE.md
   - **Xcode apps**: Project files via `agvtool`, README.md, CLAUDE.md
9. Commits changes
10. Force pushes to development (safe with `--force-with-lease`)
11. Creates pull request from development to main

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
