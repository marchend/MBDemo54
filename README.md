# AcmeBank iOS App

An iOS 17+ banking application built with Swift 5.10 and SwiftUI, following MVVM + Coordinator architecture.

## Quick Start

```bash
git clone <repo>
cd AcmeBank
./setup.sh
```

`setup.sh` installs [XcodeGen](https://github.com/yonaskolb/XcodeGen) if missing, generates
`AcmeBank.xcodeproj` from `project.yml`, and opens it in Xcode.

**Manual fallback** (for environments that block shell scripts):
```bash
brew install xcodegen
xcodegen generate
open AcmeBank.xcodeproj
```

## Run Tests

- **Xcode:** ⌘U
- **CLI:** `xcodebuild test -scheme AcmeBank -destination 'platform=iOS Simulator,name=iPhone 16'`

## Project Structure

The Xcode project is **generated** from `project.yml` — never commit `*.xcodeproj`.
Source files live under `AcmeBank/` and are auto-discovered by XcodeGen directory globs.

See [CLAUDE.md](CLAUDE.md) for full architecture documentation, planned features, and git workflow.

## Status

🚧 Bootstrap — Hello World scaffold only. All banking features are in upcoming PRs.
