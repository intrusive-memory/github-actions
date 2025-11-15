# Shared GitHub Actions

Reusable GitHub Actions for intrusive-memory projects.

## Available Actions

### [version-bump](./version-bump/)

Automatically bumps version numbers after GitHub releases for Swift packages and Xcode apps.

**Key Features:**
- Uses git tags as the single source of truth for versioning
- Auto-detects project type (Swift package vs Xcode app)
- Updates all version references across the repository
- Rebases development onto main before bumping
- Creates PR automatically

**Quick Start:**

```yaml
- name: Bump version
  uses: intrusive-memory/github-actions/version-bump@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

[See full documentation →](./version-bump/README.md)

## Usage in Projects

These actions are used in:
- [SwiftCompartido](https://github.com/intrusive-memory/SwiftCompartido) - Swift package for screenplay management
- [Produciesta](https://github.com/intrusive-memory/Produciesta) - macOS screenplay app
- [SwiftHablare](https://github.com/intrusive-memory/SwiftHablare) - Swift text-to-speech package

## Contributing

When updating actions, follow semantic versioning for tags:
- **Patch** (v1.0.x): Bug fixes, no behavior changes
- **Minor** (v1.x.0): New features, backward compatible
- **Major** (vx.0.0): Breaking changes

Projects using `@v1` will automatically get minor and patch updates.
