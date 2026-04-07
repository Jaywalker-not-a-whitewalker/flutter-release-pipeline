# Flutter Release Pipeline Skill

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Claude](https://img.shields.io/badge/Claude-Supported-blueviolet)
![Codex](https://img.shields.io/badge/Codex-Supported-green)
![Antigravity](https://img.shields.io/badge/Antigravity-Supported-orange)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)

A production-grade, cross-agent skill that automates your entire Flutter release process in one command. Works on macOS, Linux, and Windows.

## Compatible Agents
| Agent        | Trigger Command                  |
|--------------|----------------------------------|
| Claude Code  | `/flutter-release-pipeline`      |
| OpenAI Codex | `$flutter-release-pipeline`      |
| Antigravity  | `run flutter release pipeline`   |

## What It Does
- ✅ Detects OS automatically (macOS, Linux, Windows) and uses the right commands
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
- **Windows**: PowerShell 5.1 or later (comes with Windows 10/11)

## One-Line Install

### Claude Code
```bash
mkdir -p ~/.claude/skills/flutter-release-pipeline && \
curl -o ~/.claude/skills/flutter-release-pipeline/SKILL.md \
https://raw.githubusercontent.com/Jaywalker-not-a-whitewalker/flutter-release-pipeline/main/SKILL.md
```

### OpenAI Codex
```bash
mkdir -p ~/.codex/skills/flutter-release-pipeline && \
curl -o ~/.codex/skills/flutter-release-pipeline/SKILL.md \
https://raw.githubusercontent.com/Jaywalker-not-a-whitewalker/flutter-release-pipeline/main/SKILL.md
```

### Antigravity
```bash
mkdir -p ~/.antigravity/skills/flutter-release-pipeline && \
curl -o ~/.antigravity/skills/flutter-release-pipeline/SKILL.md \
https://raw.githubusercontent.com/Jaywalker-not-a-whitewalker/flutter-release-pipeline/main/SKILL.md
```

### Windows (PowerShell)
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills\flutter-release-pipeline"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Jaywalker-not-a-whitewalker/flutter-release-pipeline/main/SKILL.md" `
  -OutFile "$env:USERPROFILE\.claude\skills\flutter-release-pipeline\SKILL.md"
```

## Usage
Navigate to any Flutter project root and type:

/flutter-release-pipeline

Or say naturally:

cut a release
run release pipeline
bump version and release


## Cross-Platform Support

| Feature                  | macOS/Linux         | Windows (PowerShell)         |
|--------------------------|---------------------|------------------------------|
| OS Auto-Detection        | ✅                  | ✅                           |
| Directory creation       | `mkdir -p`          | `New-Item -Force`            |
| File append              | `echo >> file`      | `Add-Content`                |
| Temp file                | `/tmp/`             | `$env:TEMP\`                 |
| flutter test             | ✅                  | ✅                           |
| flutter build appbundle  | ✅                  | ✅                           |
| flutter build apk        | ✅                  | ✅                           |
| Git operations           | ✅                  | ✅                           |

## Project Structure After First Run

your-flutter-app/
├── pubspec.yaml
├── flutter_release_config.json ← auto-created, git-ignored
├── .gitignore ← auto-updated
└── DOCs/
├── test_results.csv
├── releases.csv
└── releases/
└── release_notes_1_0_5.md

## License
MIT — free to use, modify, and distribute.