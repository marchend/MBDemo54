# AcmeBank — Project Context

## Overview
AcmeBank is an iOS 17+ banking app built in Swift/SwiftUI. It lets customers view accounts
and transactions, initiate transfers, manage cards, and authenticate via Okta OIDC.
This repo currently contains the Hello-World bootstrap; all banking features are in future PRs.

## Tech Stack
| Item | Choice |
|---|---|
| Platform | iOS 17+, Xcode 16.0 |
| Language | Swift 5.10 |
| UI Framework | SwiftUI |
| Architecture | MVVM + Coordinator (`NavigationStack`) |
| Auth | Okta OIDC (`okta-mobile-swift` 2.x) |
| Networking | `URLSession` + async/await |
| DI | Constructor injection (no service locator) |
| Notifications | `NotificationCenter` with typed wrappers |
| Test (unit) | XCTest (`AcmeBankTests/`) |
| Test (UI) | XCUITest (`AcmeBankUITests/`) — future PR |
| Project file | XcodeGen `project.yml` (never hand-craft `.pbxproj`) |
| Bundle ID | `com.acmebank.mobile` |

## Setup
```bash
git clone <repo> && cd AcmeBank
./setup.sh          # installs xcodegen if missing, generates .xcodeproj, opens Xcode
```
Manual fallback: `brew install xcodegen && xcodegen generate && open AcmeBank.xcodeproj`

## Run Tests
- Xcode: ⌘U
- CLI: `xcodebuild test -scheme AcmeBank -destination 'platform=iOS Simulator,name=iPhone 16'`

## Key Directory Structure
```
AcmeBank/               ← iOS source root (XcodeGen glob picks up all .swift here)
  App/                  ← @main entry + RootView + AppCoordinator (implemented: App entry only)
  Core/Auth/            ← AuthService, KeychainStore, UserSession (deferred)
  Core/Networking/      ← APIClient, APIRouter, APIError, RequestInterceptor (deferred)
  Core/Notifications/   ← AppNotification, NotificationPublisher (deferred)
  Core/Extensions/      ← Decimal+Currency, Date+Greeting, String+Initials (deferred)
  Domain/Models/        ← Account, Transaction, Customer, TransferRequest (deferred)
  Domain/Repositories/  ← Protocol-only repo interfaces (deferred)
  Data/Remote/          ← APIRepository implementations (deferred)
  Data/Mock/            ← MockRepository implementations (deferred)
  Features/Login/       ← LoginView, LoginViewModel, LoginCoordinator (deferred)
  Features/Home/        ← HomeView, HomeViewModel, HomeCoordinator (deferred)
  Features/Accounts/    ← (deferred)
  Features/Transfer/    ← (deferred)
  Features/Cards/       ← (deferred)
  DesignSystem/         ← Colors, Typography, Assets.xcassets (deferred)
  Resources/            ← Localizable.strings, Okta.plist.example (deferred)
AcmeBankTests/          ← XCTest unit tests (one smoke test implemented)
AcmeBankUITests/        ← XCUITest end-to-end (deferred)
project.yml             ← XcodeGen spec (source of truth for .xcodeproj)
setup.sh                ← one-shot setup script
```

## Planned Architecture (from spec)

### MVVM + Coordinator
- **View** — SwiftUI `View` struct; renders from ViewModel `@Published` state; zero business logic. _(deferred — future PR)_
- **ViewModel** — `final class: ObservableObject`; holds `@Published` state; calls repositories; no SwiftUI imports. _(deferred — future PR)_
- **Coordinator** — `ObservableObject` owning `NavigationPath`; drives push/present declaratively. _(deferred — future PR)_
- **AppCoordinator** — root coordinator; switches Login vs TabBar on auth state; listens for `sessionExpired`. _(deferred — future PR)_
- **App entry point** — `@main AcmeBankApp: App` with `WindowGroup { ContentView() }`. _(implemented in this PR — placeholder ContentView)_

### Auth (Okta OIDC)
- `AuthService` / `AuthServiceProtocol` — Okta browser OIDC flow, token decode, Keychain persistence. _(deferred — future PR)_
- `KeychainStore` — read/write access token + refresh token. _(deferred — future PR)_
- `UserSession` — value type carrying userId, displayName, email, accessToken, authTimestamp, deviceName. _(deferred — future PR)_
- `RequestInterceptor` — injects Bearer token; posts `sessionExpired` on refresh failure. _(deferred — future PR)_

### Networking
- `APIClient` — `URLSession` wrapper; decodes via `JSONDecoder` (snake_case, iso8601); maps HTTP errors to `APIError`. _(deferred — future PR)_
- `APIRouter` — endpoint enum (accounts, transactions, transfers, bills). _(deferred — future PR)_

### Domain Models
- `Account`, `Transaction`, `Customer`, `TransferRequest` — `Identifiable & Codable` value types. _(deferred — future PR)_
- Repository protocols in `Domain/Repositories/`; concrete implementations in `Data/`. _(deferred — future PR)_

### Design System
- `Colors.swift` — `Color` extensions (acmeNavy, acmeBackground, etc.). _(deferred — future PR)_
- `Typography.swift` — `Font` extensions with Dynamic Type support. _(deferred — future PR)_

### Notifications
- `AppNotification` — typed `Notification.Name` constants. _(deferred — future PR)_
- `NotificationPublisher` — thin wrapper around `NotificationCenter.default.post`. _(deferred — future PR)_

### Testing
- XCTest unit tests for every ViewModel (≥80% coverage on `Core/` and `Features/`). _(deferred — future PR)_
- XCUITest for critical flows: Login, Transfer, Sign-Out. _(deferred — future PR)_
- CI: `xcodebuild test`, SwiftLint, warnings-as-errors, xcconfig secret injection. _(deferred — future PR)_

## Deferred Work
- Okta OIDC authentication (AuthService, KeychainStore, UserSession, Okta.plist)
- Login / Home / Accounts / Transfer / Cards screens + ViewModels + Coordinators
- URLSession networking layer (APIClient, APIRouter, APIError, RequestInterceptor)
- Domain models + Repository protocols + Remote/Mock implementations
- Design system (Colors, Typography, Assets)
- NotificationCenter typed wrappers (AppNotification, NotificationPublisher)
- XCUITest end-to-end target + Login/Transfer/SignOut UI tests
- CI workflow (ios-build.yml, SwiftLint, xcconfig injection, warnings-as-errors)
- TabBarCoordinator + full coordinator hierarchy
- Localizable.strings + Okta.plist.example

## Git Workflow

> **Default PR target branch: `develop`.** Every feature/refactor/docs PR
> opens against `develop`. PRs are only opened against `qa`, `uat`, or
> `main` for explicit promotion PRs.

**Branch model (`develop` → `qa` → `uat` → `main`):**

| Branch  | Role                                 | Receives PRs from              | Promotes to |
|---------|--------------------------------------|--------------------------------|-------------|
| develop | Default integration branch           | feature branches               | qa          |
| qa      | First quality gate                   | develop (promotion PR)         | uat         |
| uat     | Pre-prod acceptance                  | qa (promotion PR)              | main        |
| main    | Production / release tags            | uat (promotion PR)             | tagged only |

All feature PRs MUST target `develop`. Never open a feature PR against
`qa`, `uat`, or `main`. Promotions happen via dedicated promotion PRs.
