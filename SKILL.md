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
- DATA PERSISTENCE: Always APPEND to CSV files. Never overwrite existing data.
- PATH RETENTION: Write all confirmed paths to flutter_release_config.json in the project root. Read from it in every subsequent step. Never ask for the same path twice.
- GITIGNORE PROTECTION: Always ensure flutter_release_config.json is in .gitignore.
- CROSS-PLATFORM: Always detect OS first (Step 0.0) and use correct commands throughout.
- NO EARLY GIT CHECKS: Never run any git write operation before Step 8. git status is only used in Step 8.1 as informational display.

## Pipeline Overview
Step 0  - Environment Setup (OS + Flutter check + Config + gitignore + Releases dir)
Step 1  - Run Tests (GATE)
Step 2  - Bump Version
Step 3  - Log Test Results to CSV
Step 4  - Extract Changes and Generate Release Notes
Step 5  - Log Release to CSV
Step 6  - Review and Confirm Release Notes (GATE)
Step 7  - Build
         7.1 iOS Archive Preparation (GATE)
         7.2 Android Build (AAB / APK / Skip)          AFTER
Step 8  - Git Operations (status -> stage -> commit -> tag -> push)
Finish  - Completion Summary

## Step 0: Environment and Path Verification

### 0.0 OS Detection (CRITICAL - Run First)
1. Detect the operating system.
2. Set OS context for all subsequent steps:
   - macOS/Linux: use Unix commands (mkdir -p, echo >>, ls, basename $PWD, /tmp/)
   - Windows: use PowerShell commands (New-Item -Force, Add-Content, dir, Split-Path -Leaf, $env:TEMP\)
3. Confirm: "OS Detected: [macOS / Linux / Windows]."

Cross-Platform Command Reference:

| Operation         | macOS/Linux                       | Windows PowerShell                                  |
|-------------------|-----------------------------------|-----------------------------------------------------|
| Create directory  | mkdir -p <path>                   | New-Item -ItemType Directory -Force -Path "<path>"  |
| Append to file    | echo "text" >> file               | Add-Content -Path "file" -Value "text"              |
| Create new file   | echo "text" > file                | Set-Content -Path "file" -Value "text"              |
| List directory    | ls <path>                         | dir "<path>"                                        |
| Check file exists | test -f <file>                    | Test-Path "<file>"                                  |
| Check dir exists  | test -d <dir>                     | Test-Path -PathType Container "<dir>"               |
| Get project name  | basename $PWD                     | Split-Path -Leaf (Get-Location)                     |
| Temp file         | /tmp/flutter_test_output.json     | $env:TEMP\flutter_test_output.json                  |
| Home directory    | ~/                                | $env:USERPROFILE\                                   |
| Read file         | cat <file>                        | Get-Content "<file>"                                |
| Path separator    | /                                 | \                                                   |

### 0.1 Flutter Project Check
1. Confirm pubspec.yaml exists in the current directory.
2. IF MISSING: STOP - "This does not appear to be a Flutter project root. Please navigate to your Flutter project root directory and try again."

### 0.2 Load or Create Config (flutter_release_config.json)
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
   - If 1: load paths and skip to Step 0.3.
   - If 2: proceed to re-configure below.
3. IF MISSING or re-configuring:
   a. Check if DOCs/ exists in the project root.
      - IF EXISTS: Ask:
      "DOCs/ folder found.
         1. Use existing DOCs/ folder
         2. Enter a different folder path"
      - IF MISSING: Ask:
      "DOCs/ folder not found. Please choose:
         1. Create DOCs/ now (recommended)
         2. Enter a custom folder path"
      - If 1:
         macOS/Linux: mkdir -p DOCs/releases
         Windows:     New-Item -ItemType Directory -Force -Path "DOCs\releases"
         Use DOCs/ as docs_root.
      - If 2: ask user for path, validate:
         macOS/Linux: ls <path>
         Windows:     dir "<path>"
         - Valid: use it.
         - Invalid: ask "1. Create it now  2. Enter a different path"
            Loop until resolved.
   b. Write flutter_release_config.json to project root:
      {
      "project_name": "<project_name>",
      "os": "<macos|linux|windows>",
      "docs_root": "ed_path>",
      "releases_dir": "ed_path>/releases",
      "test_results_csv": "ed_path>/test_results.csv",
      "releases_csv": "ed_path>/releases.csv"
      }
      Note: On Windows use backslash in all paths inside the JSON.
   c. Confirm: "Config saved to flutter_release_config.json"

### 0.3 .gitignore Protection
1. Check if .gitignore exists.
   - If yes: check if flutter_release_config.json is already listed.
   - If not listed:
      macOS/Linux: echo "flutter_release_config.json" >> .gitignore
      Windows:     Add-Content -Path ".gitignore" -Value "flutter_release_config.json"
   - If missing:
      macOS/Linux: echo "flutter_release_config.json" > .gitignore
      Windows:     Set-Content -Path ".gitignore" -Value "flutter_release_config.json"
2. Confirm: "flutter_release_config.json is protected in .gitignore"

### 0.4 Releases Sub-directory Check
1. Read releases_dir from flutter_release_config.json.
2. If the directory does not exist:
   macOS/Linux: mkdir -p <releases_dir>
   Windows:     New-Item -ItemType Directory -Force -Path "<releases_dir>"
3. Confirm: "Releases directory verified."

## Step 1: Run Tests
1. Run:
   macOS/Linux: flutter test --reporter json 2>&1 | tee /tmp/flutter_test_output.json
   Windows:     flutter test --reporter json 2>&1 | Tee-Object -FilePath "$env:TEMP\flutter_test_output.json"
2. Parse JSON output to extract:
   - All individual test case names
   - Total tests run
   - Passed count
   - Failed count
3. Show a clean summary to the user.

### GATE - Tests FAILED:
- Do NOT proceed to Step 2.
- Read test_results_csv from config. If missing, create with headers:
Date,Version,Test_cases,Total Tests,Passed,Failed,Status
- Append (current version - not yet bumped):
[Date],[Current Version],[test names separated by ;],[Total],[Passed],[Failed],Failed
- Present recovery options:
"Tests failed. Results logged to test_results.csv.
   How would you like to proceed?
   1. Retry tests
   2. Analyze errors and suggest fixes
   3. Analyze errors and fix automatically
   4. Cancel release (already logged as Failed)"
- Act on user choice. Do NOT continue pipeline unless a retry fully passes.

### GATE - Tests PASSED:
- Confirm: "All tests passed. Proceeding to version bump."
- Do NOT log to CSV yet - bumped version needed first (see Step 3).

## Step 2: Bump Version
1. Read the version: line from pubspec.yaml (e.g., version: 1.0.4+5).
2. Increment patch version and build number (e.g., 1.0.4+5 to 1.0.5+6).
3. Write the updated version back to pubspec.yaml.
4. Store OLD_VERSION for potential revert use in Steps 6 and 7.
5. Confirm: "Version bumped: 1.0.4+5 to 1.0.5+6"

## Step 3: Log Test Results to CSV
New version is now available - safe to log now.
1. Read test_results_csv from config. If missing, create with headers:
   Date,Version,Test_cases,Total Tests,Passed,Failed,Status
2. Append:
   [Date],[New Version],[test names separated by ;],[Total],[Passed],[Failed],Passed
3. Confirm: "Test results logged to test_results.csv"

## Step 4: Extract Changes and Generate Release Notes
1. Run:
   macOS/Linux: git log $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD --pretty=format:"- %s"
   Windows:     git log --pretty=format:"- %s" $(git describe --tags --abbrev=0)
2. Read releases_dir from config.
3. Create file: <releases_dir>/release_notes_<version_with_underscores>.md
   Example: DOCs/releases/release_notes_1_0_5.md
4. Write the following content:
   # Release Notes - v[NEW_VERSION]
   **Date:** [Current Date]
   **Build:** [Build Number]
   **Platform:** [OS]

   ## Changes
   [formatted commit list]
5. Confirm: "Release notes draft created: <path>"

## Step 5: Log Release to CSV
1. Read releases_csv from config. If missing, create with headers:
   Date,Version,Release Notes File Path,Changes
2. Append:
   [Date],[New Version],<releases_dir>/release_notes_X_X_X.md,"[changes as single line; semicolon separated]"
3. Confirm: "Release logged to releases.csv"

## Step 6: Review and Confirm Release Notes (CRITICAL GATE)
This step MUST happen before any build or git operation.

1. Read and display the full contents of the generated release notes file to the user.
2. Show:
   "Release Notes for v[NEW_VERSION]:
   -----------------------------------------
   [Full contents of release_notes_X_X_X.md]
   -----------------------------------------
   How would you like to proceed?
   1. Looks good - proceed to build
   2. Edit release notes - I will provide new content
   3. Regenerate from git log - re-extract commits
   4. Cancel release"

3. If user chooses 1: proceed to Step 7.
4. If user chooses 2:
   - Ask: "Please provide the updated release notes content."
   - Overwrite the release notes file with user input.
   - Update the Changes column in releases.csv with new content.
   - Show updated notes and ask: "1. Confirm  2. Edit again"
   - Loop until user confirms.
5. If user chooses 3:
   - Re-run the git log command from Step 4.
   - Overwrite release notes file with freshly extracted commits.
   - Show new notes and return to top of Step 6.
6. If user chooses 4:
   - STOP the entire pipeline.
   - Revert pubspec.yaml version back to OLD_VERSION.
   - Inform: "Release cancelled. pubspec.yaml reverted to [OLD_VERSION]. CSV logs retained for audit."
   - Do NOT delete any CSV logs already written.

## Step 7: Build

### 7.1 iOS Archive Preparation (GATE)
IMPORTANT: This step runs before Android because flutter clean wipes the entire
build/ folder. Running iOS prep first ensures the Android build output is never deleted.
NOTE: Only available on macOS. Skip automatically on Windows/Linux.

1. Ask the user how to proceed:
   "iOS Archive Preparation
   This will prepare your project for Xcode archiving:
      - flutter clean      (clears build folder)
      - flutter pub get    (picks up version bump)
      - pod deintegrate    (removes old pod linkages)
      - pod install        (re-syncs pods with Xcode)

   How would you like to proceed?
   1. Run iOS prep - then continue to Android build
   2. Run iOS prep - open Xcode for archiving - then continue to Android build
   3. Skip iOS prep - go straight to Android build"

2. If user chooses 1 or 2:
   a. Run: flutter clean
      Confirm: "flutter clean complete - build/ folder cleared."
   b. Run: flutter pub get
      Confirm: "flutter pub get complete - version bump picked up."
   c. Run: cd ios && pod deintegrate
      Confirm: "pod deintegrate complete."
   d. Run: pod install
      Confirm: "pod install complete - pods synced with Xcode."
   e. Run: cd ..
      Confirm: "Returned to project root."
   f. If user chose 2:
      - Run: open ios/Runner.xcworkspace
      - Show:
      "Xcode is opening with version [NEW_VERSION].
         Complete the archive in Xcode:
         1. Select Any iOS Device as target
         2. Product -> Archive
         3. Organizer -> Distribute App
         4. Upload to App Store Connect or export IPA
         Type 'done' when Xcode archiving is complete."
      - Wait for user to confirm 'done' before proceeding.
   g. Confirm: "iOS prep complete. Proceeding to Android build."

3. If user chooses 3:
   - Confirm: "iOS prep skipped. Proceeding to Android build."
   - Note: flutter clean was NOT run. Android builds into existing build/ folder.

4. If iOS prep FAILS at any sub-step: STOP. Show full error. Ask:
   "iOS prep failed at: [sub-step]. Error: [error output]
   1. Retry this sub-step
   2. Skip iOS prep and continue to Android
   3. Cancel release - revert pubspec.yaml to [OLD_VERSION]"

### 7.2 Android Build (Runs AFTER iOS prep)
1. Ask:
   "Android Build. Choose an option:
   1. Build App Bundle (AAB) - recommended for Play Store
      -> flutter build appbundle --release
   2. Build APK - for direct distribution
      -> flutter build apk --release
   3. Skip Android build - proceed to git operations"

2. If 1: run flutter build appbundle --release
   Output path:
   macOS/Linux: build/app/outputs/bundle/release/app-release.aab
   Windows:     build\app\outputs\bundle\release\app-release.aab
   Confirm: "AAB built successfully: <output_path>"

3. If 2: run flutter build apk --release
   Output path:
   macOS/Linux: build/app/outputs/flutter-apk/app-release.apk
   Windows:     build\app\outputs\flutter-apk\app-release.apk
   Confirm: "APK built successfully: <output_path>"

4. If 3: skip and proceed to Step 8.

5. If build FAILS: STOP. Show full error output. Ask:
   "Android build failed.
   1. Retry build
   2. Cancel release - revert pubspec.yaml to [OLD_VERSION]"


## Step 8: Git Operations
This is the ONLY step where any git write operation happens.
No git commits, tags, or pushes occur before this step.

### 8.1 Show Git Status (Informational Only)
1. Run: git status --short
2. Display all changed files to the user:
   "The following files will be committed:
   [list of all changed files]"
3. This is informational only. Proceed immediately to 8.2.

### 8.2 Stage Files
1. Read docs_root from config.
2. Stage all release-related files:
   git add pubspec.yaml <docs_root>/ .gitignore flutter_release_config.json
3. Confirm: "Files staged successfully."

### 8.3 Commit, Tag and Push
Ask:
   "Ready to commit v[NEW_VERSION]. What would you like to do?
   1. Commit + Tag only (local)
      -> git commit -m 'chore(release): bump version to [NEW_VERSION]'
      -> git tag v[NEW_VERSION]
   2. Commit + Tag + Push (remote)
      -> git commit -m 'chore(release): bump version to [NEW_VERSION]'
      -> git tag v[NEW_VERSION]
      -> git push
      -> git push --tags
   3. Skip - do not commit"

Execute based on user choice.
Confirm: "Git operations complete." or "Git operations skipped."

## Completion Summary
Output a formatted summary:
╔══════════════════════════════════════════════════════════════╗
║           🎉 Flutter Release Pipeline Complete               ║
╠══════════════════════════════════════════════════════════════╣
║  Project       : <project_name>                              ║
║  OS            : <macOS / Linux / Windows>                   ║
║  New Version   : <new_version>                               ║
║  iOS Prep      : <Completed / Xcode Opened / Skipped>        ║
║  Android Build : <AAB path / APK path / Skipped>             ║
║  Release Notes : <releases_dir>/release_notes_X_X_X.md      ║
║  Releases CSV  : <releases_csv path>                         ║
║  Test Results  : <test_results_csv path>                     ║
║  Git Tag       : v<new_version> (pushed / local / skipped)   ║
╚══════════════════════════════════════════════════════════════╝