---
name: changelog-generator
description: Automatically creates user-facing changelogs from git commits by analyzing commit history, categorizing changes, and transforming technical commits into clear, customer-friendly release notes in Keep a Changelog format.
---

# Changelog Generator

This skill transforms technical git commits into polished changelogs following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) standard — readable by humans, not just machines.

## When to Use This Skill

- Preparing release notes for a new version
- Maintaining a `CHANGELOG.md` file in a project
- Documenting changes for customers or users
- Creating GitHub release descriptions
- Writing app store update descriptions
- Generating internal release documentation

## What This Skill Does

1. **Scans Git History**: Analyzes commits from a specific time period or between version tags
2. **Categorizes Changes**: Groups commits into the six Keep a Changelog categories
3. **Translates Technical → Human-Readable**: Converts developer commits into clear language
4. **Formats to Standard**: Outputs valid Keep a Changelog Markdown
5. **Filters Noise**: Excludes internal commits (refactoring, tests, CI, chore)
6. **Handles Unreleased**: Supports an `[Unreleased]` section for upcoming changes

## Keep a Changelog Format

### Core Principles

Changelogs are written **for humans, not machines**. The format follows these rules:

- Latest version appears **first** (reverse chronological order)
- Each version has its **own section** with a date in `YYYY-MM-DD` (ISO 8601)
- Changes are grouped into **consistent categories**
- An `[Unreleased]` section tracks changes not yet in a release
- Versions follow [Semantic Versioning](https://semver.org/)
- Yanked releases are marked with `[YANKED]`

### The Six Change Categories

Only include categories that have entries — omit empty ones:

| Category | When to use |
|---|---|
| `Added` | New features |
| `Changed` | Changes to existing functionality |
| `Deprecated` | Features that will be removed in a future release |
| `Removed` | Features removed in this release |
| `Fixed` | Bug fixes |
| `Security` | Vulnerability fixes |

### File Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature not yet released

## [1.2.0] - 2024-03-15

### Added
- ...

### Fixed
- ...

## [1.1.0] - 2024-02-01

### Changed
- ...

## [1.0.0] - 2024-01-10

### Added
- Initial release

[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

### What NOT to Include

- Raw git commit messages or diff dumps
- Internal/technical changes (refactoring, test changes, CI config, dependency bumps without user impact)
- Merge commits
- Changes to dev tooling with no user-facing effect

## How to Use

### Basic Usage

```
Create a changelog from commits since last release
```

```
Generate changelog entries for commits from the past week
```

```
Create changelog for version 2.5.0
```

### With Specific Range

```
Create changelog entries for all commits between v2.4.0 and v2.5.0
```

```
Add changelog entries for commits from March 1 to March 15 to CHANGELOG.md
```

### Unreleased Section

```
Update the [Unreleased] section in CHANGELOG.md with commits since v1.2.0
```

## Example

**User**: "Create a changelog for commits from the past 7 days, version 2.5.0"

**Output**:

```markdown
## [2.5.0] - 2024-03-15

### Added
- Team workspaces: create separate workspaces per project and invite members
- Keyboard shortcuts panel — press `?` to see all available shortcuts

### Changed
- File sync is now 2x faster across devices
- Search now includes file contents, not just titles

### Fixed
- Large images no longer fail to upload
- Notification badge count now updates correctly
- Scheduled posts no longer show incorrect timezones
```

## Process

When generating a changelog, follow these steps:

1. **Get commit history**: Run `git log` for the relevant range
   ```bash
   git log v1.1.0..HEAD --oneline
   # or for a date range:
   git log --since="2024-03-01" --until="2024-03-15" --oneline
   ```

2. **Filter commits**: Remove chore, test, refactor, ci, docs commits unless they have user impact

3. **Map to categories**:
   - `feat:` → `Added`
   - `fix:` → `Fixed`
   - `BREAKING CHANGE` → `Changed` or `Removed`
   - `security:` → `Security`
   - `deprecate:` → `Deprecated`
   - Removed features → `Removed`

4. **Rewrite for humans**: Transform technical commit messages into plain language describing the user benefit

5. **Output**: Either print the section or append/prepend to `CHANGELOG.md`

## Tips

- Run from the git repository root
- When updating an existing `CHANGELOG.md`, prepend the new version above the previous latest version
- Move items from `[Unreleased]` to the new version section when cutting a release
- Always use `YYYY-MM-DD` for dates — never "March 15" or "15/03/2024"
- Add version comparison links at the bottom of the file when a GitHub remote is available
