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

## Okta build configuration

The Okta tenant settings (issuer, client ID, redirect URI, scopes) are **not** committed
to this repo. They reach the built app through an Xcode **Run Script** build phase
(`Scripts/inject-okta-config.sh`) that reads four environment variables from the
calling process and writes them into the built `Info.plist` via `plutil -replace`.
The app then reads them at runtime via `Bundle.main.infoDictionary`.

> **Why a Run Script and not an `.xcconfig`?** An `.xcconfig` `$(VAR)` reference chains
> *other build settings* — it does **not** interpolate shell environment variables. So
> the obvious `.xcconfig` path silently ships an app with empty Okta values unless a
> developer remembers a manual prepare step. A Run Script phase **does** inherit
> Xcode's process environment, so once you've set the env vars on the build machine,
> every `xcodebuild` / Run from Xcode picks them up with no further steps. The script
> uses `set -e` + `${VAR:?…}` so a missing env var **fails the build immediately** with
> the variable name in the error, instead of shipping an empty value.

### Required environment variables

| Variable            | Example                                      |
|---------------------|----------------------------------------------|
| `OKTA_ISSUER`       | `https://example.okta.com/oauth2/default`    |
| `OKTA_CLIENT_ID`    | `0oa1abcDEFghIJklm2n7`                       |
| `OKTA_REDIRECT_URI` | `com.acmebank.mobile:/callback`              |
| `OKTA_SCOPES`       | `openid profile email offline_access`        |

### How to set them so Xcode sees them

Pick **one** of the two paths below depending on how you launch Xcode.

**(a) Xcode launched from Finder / Dock / Spotlight (GUI launch).**
GUI-launched apps inherit only the `launchd` user-session environment, not your
shell's environment. Set the vars on `launchd` once:

```bash
launchctl setenv OKTA_ISSUER       "https://example.okta.com/oauth2/default"
launchctl setenv OKTA_CLIENT_ID    "0oa1abcDEFghIJklm2n7"
launchctl setenv OKTA_REDIRECT_URI "com.acmebank.mobile:/callback"
launchctl setenv OKTA_SCOPES       "openid profile email offline_access"
```

Then fully quit and relaunch Xcode (the values are read on Xcode launch).

**(b) Xcode launched from a terminal via `xed .` (shell launch).**
Shell-launched Xcode inherits the calling shell's environment. Add to `~/.zshrc`:

```bash
export OKTA_ISSUER="https://example.okta.com/oauth2/default"
export OKTA_CLIENT_ID="0oa1abcDEFghIJklm2n7"
export OKTA_REDIRECT_URI="com.acmebank.mobile:/callback"
export OKTA_SCOPES="openid profile email offline_access"
```

Then open a **fresh** terminal (so `.zshrc` is re-sourced) and run:

```bash
cd path/to/AcmeBank
xed .
```

### Verification

- **Build with any `OKTA_*` unset** → the build fails immediately with a message like
  `OKTA_ISSUER: OKTA_ISSUER not set` and exit status non-zero. This is intentional.
- **Build with all four set** → inspect the built bundle's `Info.plist`:
  ```bash
  plutil -p "$(xcodebuild -showBuildSettings -scheme AcmeBank | awk -F= '/TARGET_BUILD_DIR/ {print $2}' | xargs)/AcmeBank.app/Info.plist" \
    | grep -i okta
  ```
  You should see the four `Okta*` keys populated with your env-var values.

### What is **not** committed

No `Okta.plist`, no `.xcconfig`, no `.env` with Okta values ever land in the repo.
`.gitignore` defensively excludes `*.xcconfig`, `**/Okta.plist`, and `.env*`. The
build machine's environment is the **single source of truth** for Okta config.

## Run Tests

- **Xcode:** ⌘U
- **CLI:** `xcodebuild test -scheme AcmeBank -destination 'platform=iOS Simulator,name=iPhone 16'`

## Running locally

After `./setup.sh` and setting the four `OKTA_*` env vars as above, hit Run in Xcode.

**Cold-launch behaviour** (full flow ships across the MD054-2 PRs):

- **No refresh token in Keychain** → app lands on the **Login** screen and the user
  signs in via Okta. On success the ID-token claims populate a `UserSession` and the
  app navigates to **Landing**.
- **Valid refresh token in Keychain** (after a prior login with "Keep me signed in"
  checked) → the app silently refreshes tokens on launch and goes **straight to
  Landing**, skipping Login.

## Project Structure

The Xcode project is **generated** from `project.yml` — never commit `*.xcodeproj`.
Source files live under `AcmeBank/` and are auto-discovered by XcodeGen directory globs.

See [CLAUDE.md](CLAUDE.md) for full architecture documentation, planned features, and git workflow.

## Status

🚧 Bootstrap → wiring Okta. Login screen UI + Okta auth flow land across the MD054-2 PRs.
