# Flutter Release Pipeline Skill

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Claude](https://img.shields.io/badge/Claude-Supported-blueviolet)
![Codex](https://img.shields.io/badge/Codex-Supported-green)
![Antigravity](https://img.shields.io/badge/Antigravity-Supported-orange)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)

A production-grade, cross-agent skill that automates your entire Flutter release process in one command.

## Compatible Agents
| Agent        | Trigger Command                  |
|--------------|----------------------------------|
| Claude Code  | `/flutter-release-pipeline`      |
| OpenAI Codex | `$flutter-release-pipeline`      |
| Antigravity  | `run flutter release pipeline`   |

## What It Does
- ✅ Verifies Flutter project root and git status
- ✅ Saves and reuses docs path via `flutter_release_config.json`
- ✅ Runs `flutter test` with structured JSON parsing
- ✅ Bumps patch version and build number in `pubspec.yaml`
- ✅ Logs test results to `DOCs/test_results.csv`
- ✅ Extracts git commit messages and generates markdown release notes
- ✅ Logs releases to `DOCs/releases.csv`
- ✅ Builds AAB or APK with correct output paths
- ✅ Stages, commits, tags, and optionally pushes to remote

## Prerequisites
- Flutter SDK installed and on PATH
- Git initialized in your project
- Run from the Flutter project root directory

## One-Line Install

### Claude Code
```bash
mkdir -p ~/.claude/skills/flutter-release-pipeline && \
curl -o ~/.claude/skills/flutter-release-pipeline/SKILL.md \
https://raw.githubusercontent.com/YOUR_USERNAME/flutter-release-pipeline/main/SKILL.md
```

### OpenAI Codex
```bash
mkdir -p ~/.codex/skills/flutter-release-pipeline && \
curl -o ~/.codex/skills/flutter-release-pipeline/SKILL.md \
https://raw.githubusercontent.com/YOUR_USERNAME/flutter-release-pipeline/main/SKILL.md
```

### Antigravity
```bash
mkdir -p ~/.antigravity/skills/flutter-release-pipeline && \
curl -o ~/.antigravity/skills/flutter-release-pipeline/SKILL.md \
https://raw.githubusercontent.com/YOUR_USERNAME/flutter-release-pipeline/main/SKILL.md
```

## Usage
Navigate to any Flutter project root and type:
