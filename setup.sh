#!/bin/bash

echo "🚀 Setting up Flutter Release Pipeline skill..."

# Create folder structure
mkdir -p agents

# ── SKILL.md ──────────────────────────────────────────────────────────────────
cat > SKILL.md << 'EOF'
---
name: flutter-release-pipeline
description: Automates the entire Flutter release process. Trigger when the user asks to "cut a release", "run release pipeline", or "bump version and release".
agents:
  - claude
  - codex
  - antigravity
---

# Flutter Release Pipeline

When triggered, execute the following steps strictly in order. If any critical step fails, STOP immediately and report the error.

## Safety Rules (CRITICAL)
- NO DELETIONS: Never use rm -rf or delete any file. Ask user first if cleanup is needed.
- CASE SENSITIVITY: Always refer to the docs folder as DOCs/ (capital D, capital C).
- DATA PERSISTENCE: Always APPEND (>>) to CSV files. Never overwrite (>).
- PATH RETENTION: Write all confirmed paths to flutter_release_config.json in the project root. Read from it in every subsequent step. Never ask for the same path twice.
- GITIGNORE PROTECTION: Always ensure flutter_release_config.json is in .gitignore.

## Step 0: Environment & Path Verification

### 0.1 Flutter Project Check
1. Confirm pubspec.yaml exists in the current directory.
2. IF MISSING: STOP — "This does not appear to be a Flutter project root. Please navigate to your Flutter project root directory and try again."

### 0.2 Git Status Check
1. Run: git status --short
2. If dirty tree detected, warn the user:
   "⚠️ Your working tree has uncommitted changes:
    1. Continue anyway
    2. Stop — I will commit/stash first"
3. Wait for user confirmation before proceeding.

### 0.3 Load or Create Config (flutter_release_config.json)
1. Check if flutter_release_config.json exists in the project root.
2. IF EXISTS:
   - Read and display saved paths.
   - Ask: "Found saved config for <project_name>:
       docs_root      : <path>
       releases_dir   : <path>
       test_results   : <path>
       releases_csv   : <path>
     1. Use this config
     2. Re-configure"
   - If 1: load paths and skip to Step 0.4.
   - If 2: proceed to re-configure below.
3. IF MISSING or re-configuring:
   a. Check if DOCs/ exists in the project root.
      - IF EXISTS: Ask:
        "1. Use existing DOCs/ folder
         2. Enter a different folder path"
      - IF MISSING: Ask:
        "DOCs/ folder not found. Please choose:
         1. Create DOCs/ now (recommended)
         2. Enter a custom folder path"
        - If 1: run mkdir -p DOCs/releases, use DOCs/ as docs_root.
        - If 2: ask for path, run ls <path> to validate:
          - Valid: use it.
          - Invalid: ask:
            "Path not found.
             1. Create it now
             2. Enter a different path"
            Loop until resolved.
   b. Once path is confirmed, write flutter_release_config.json to project root:
      {
        "project_name": "<basename $PWD>",
        "docs_root": "ed_path>",
        "releases_dir": "ed_path>/releases",
        "test_results_csv": "ed_path>/test_results.csv",
        "releases_csv": "ed_path>/releases.csv"
      }
   c. Confirm: "✅ Config saved to flutter_release_config.json"

### 0.4 .gitignore Protection
1. Check if .gitignore exists.
   - If yes: check if flutter_release_config.json is already listed.
     - If not listed: echo "flutter_release_config.json" >> .gitignore
   - If missing: echo "flutter_release_config.json" > .gitignore
2. Confirm: "✅ flutter_release_config.json is protected in .gitignore"

### 0.5 Releases Sub-directory Check
1. Read releases_dir from flutter_release_config.json.
2. If the directory does not exist: run mkdir -p <releases_dir>
3. Confirm: "✅ Releases directory verified."

## Step 1: Run Tests
1. Run: flutter test --reporter json 2>&1 | tee /tmp/flutter_test_output.json
2. Parse the JSON output to extract:
   - All individual test case names
   - Total tests run
   - Passed count
   - Failed count
3. Show a clean summary to the user.

### GATE — Tests FAILED:
- Do NOT proceed to Step 2.
- Read test_results_csv from config. If missing, create it with headers:
  Date,Version,Test_cases,Total Tests,Passed,Failed,Status
- Append (current version — not yet bumped):
  [Date],[Current Version],[test names separated by ;],[Total],[Passed],[Failed],Failed
- Present recovery options:
  "❌ Tests failed. Results logged to test_results.csv.
   How would you like to proceed?
   1. Retry tests
   2. Analyze errors and suggest fixes
   3. Analyze errors and fix automatically
   4. Cancel release (already logged as Failed)"
- Act on user choice. Do NOT continue pipeline unless a retry fully passes.

### GATE — Tests PASSED:
- Confirm: "✅ All tests passed. Proceeding to version bump."
- Do NOT log to CSV yet — the bumped version is needed first (see Step 3).

## Step 2: Bump Version
1. Read the version: line from pubspec.yaml (e.g., version: 1.0.4+5).
2. Increment patch version and build number (e.g., 1.0.4+5 → 1.0.5+6).
3. Write the updated version back to pubspec.yaml.
4. Confirm: "✅ Version bumped: 1.0.4+5 → 1.0.5+6"

## Step 3: Log Test Results to CSV
(New version is now available — safe to log now.)
1. Read test_results_csv from config. If missing, create with headers:
   Date,Version,Test_cases,Total Tests,Passed,Failed,Status
2. Append:
   [Date],[New Version],[test names separated by ;],[Total],[Passed],[Failed],Passed
3. Confirm: "✅ Test results logged to test_results.csv"

## Step 4: Extract Changes & Generate Release Notes
1. Run:
   git log $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD --pretty=format:"- %s"
2. Read releases_dir from config.
3. Create a new file: <releases_dir>/release_notes_<version_with_underscores>.md
   (e.g., DOCs/releases/release_notes_1_0_5.md)
4. Write the following content:
   # Release Notes — v[NEW_VERSION]
   **Date:** [Current Date]
   **Build:** [Build Number]

   ## Changes
   [formatted commit list]
5. Confirm: "✅ Release notes created: <path>"

## Step 5: Log Release to CSV
1. Read releases_csv from config. If missing, create with headers:
   Date,Version,Release Notes File Path,Changes
2. Append:
   [Date],[New Version],<releases_dir>/release_notes_X_X_X.md,"[changes as single line; semicolon separated]"
3. Confirm: "✅ Release logged to releases.csv"

## Step 6: Build
Prompt user:
"✅ Ready to build. Choose an option:
 1. Build App Bundle (AAB) — recommended for Play Store
 2. Build APK — for direct distribution
 3. Skip build"

- If 1: run flutter build appbundle --release
  Output path: build/app/outputs/bundle/release/app-release.aab
- If 2: run flutter build apk --release
  Output path: build/app/outputs/flutter-apk/app-release.apk
- If 3: skip and proceed to Step 7.
- If build FAILS: STOP. Show full error. Do NOT proceed to git operations.

## Step 7: Git Operations
1. Read docs_root from config.
2. Stage modified files:
   git add pubspec.yaml <docs_root>/ .gitignore flutter_release_config.json
3. Ask:
   "🚀 Pipeline complete. What would you like to do?
    1. Commit + Tag only (local)
       → git commit -m 'chore(release): bump version to [NEW_VERSION]'
       → git tag v[NEW_VERSION]
    2. Commit + Tag + Push (remote)
       → Above steps + git push && git push --tags
    3. Skip git operations"
4. Execute based on user choice.
5. Confirm the action taken.

## Completion Summary
Output a formatted summary:
╔══════════════════════════════════════════════════════════════╗
║           🎉 Flutter Release Pipeline Complete               ║
╠══════════════════════════════════════════════════════════════╣
║  Project       : <project_name>                              ║
║  New Version   : <new_version>                               ║
║  Build Output  : <aab/apk path or Skipped>                   ║
║  Release Notes : <releases_dir>/release_notes_X_X_X.md      ║
║  Releases CSV  : <releases_csv path>                         ║
║  Test Results  : <test_results_csv path>                     ║
║  Git Tag       : v<new_version> (pushed / local / skipped)   ║
╚══════════════════════════════════════════════════════════════╝
EOF

# ── agents/claude.yaml ────────────────────────────────────────────────────────
cat > agents/claude.yaml << 'EOF'
name: flutter-release-pipeline
trigger_phrases:
  - cut a release
  - run release pipeline
  - bump version and release
  - run flutter release
  - start release pipeline
notes: >
  Read flutter_release_config.json from the project root for all paths.
  Never hardcode paths. Always confirm before git operations.
EOF

# ── agents/openai.yaml ────────────────────────────────────────────────────────
cat > agents/openai.yaml << 'EOF'
name: flutter-release-pipeline
description: >
  Automates Flutter releases: bumps version, runs tests, generates
  release notes, builds AAB or APK, and tags git releases.
  Trigger with $flutter-release-pipeline or ask to "cut a release".
trigger_phrases:
  - cut a release
  - run release pipeline
  - bump version and release
  - build flutter release
config_file: flutter_release_config.json
config_scope: project_root
EOF

# ── agents/antigravity.yaml ───────────────────────────────────────────────────
cat > agents/antigravity.yaml << 'EOF'
name: flutter-release-pipeline
description: >
  Full Flutter CI/CD release pipeline. Bumps version, logs test results
  to CSV, generates markdown release notes, builds AAB or APK, and
  handles git commit and tagging. Say "run flutter release pipeline" to trigger.
category: devops
platform: flutter
language: dart
os:
  - macos
  - linux
  - windows
trigger_phrases:
  - run flutter release pipeline
  - cut a release
  - bump version and release
config_file: flutter_release_config.json
config_scope: project_root
EOF

# ── README.md ─────────────────────────────────────────────────────────────────
cat > README.md << 'EOF'
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
