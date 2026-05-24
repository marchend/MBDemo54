# Bootstrap Plan — AcmeBank iOS App

## In scope (this PR)

### Project name + tech stack decisions
- **Project:** AcmeBank iOS banking app
- **Platform:** iOS 17+, Swift 5.10, SwiftUI
- **Architecture:** MVVM + Coordinator (per spec) — bootstrapped with a single placeholder screen
- **UI Framework:** SwiftUI (`@main` App entry point, `WindowGroup`)
- **Test framework:** XCTest (unit tests in `AcmeBankTests/`)
- **Project file mechanism:** XcodeGen (`project.yml`) — never hand-crafted `.xcodeproj`
- **Bundle ID:** `com.acmebank.mobile`
- **Minimum Xcode:** 16.0

### Directory structure (bootstrap only)
```
AcmeBank/
├── project.yml                    # XcodeGen spec
├── setup.sh                       # one-shot: installs xcodegen + opens .xcodeproj
├── .gitignore                     # iOS/XcodeGen/macOS ignores
├── bootstrap_plan.md
├── README.md
├── CLAUDE.md
├── AGENT.md
├── AcmeBank/
│   └── App/
│       ├── AcmeBankApp.swift      # @main SwiftUI entry point
│       └── ContentView.swift      # placeholder screen — shows "AcmeBank"
└── AcmeBankTests/
    └── ContentViewTests.swift     # one trivial XCTest
```

### Files this PR creates
| File | Purpose |
|---|---|
| `project.yml` | XcodeGen declarative project spec (no hand-crafted pbxproj) |
| `setup.sh` | Clone→open in Xcode in one command |
| `.gitignore` | Keeps generated `.xcodeproj` and macOS noise out of git |
| `AcmeBank/App/AcmeBankApp.swift` | `@main` SwiftUI App entry — `WindowGroup { ContentView() }` |
| `AcmeBank/App/ContentView.swift` | Placeholder SwiftUI view showing `Text("AcmeBank")` |
| `AcmeBankTests/ContentViewTests.swift` | Trivial XCTest — proves XCTest target compiles and runs |
| `CLAUDE.md` | Full project context + planned architecture (deferred items marked) |
| `AGENT.md` | Byte-identical copy of CLAUDE.md |
| `README.md` | Updated with setup instructions |

### How to run locally
```bash
git clone <repo>
cd AcmeBank
./setup.sh          # installs xcodegen if missing, generates .xcodeproj, opens Xcode
```
Manual fallback: `brew install xcodegen && xcodegen generate && open AcmeBank.xcodeproj`

### How to run tests
In Xcode: ⌘U (or Product → Test)  
CLI: `xcodebuild test -scheme AcmeBank -destination 'platform=iOS Simulator,name=iPhone 16'`

### Definition of Hello World
App launches → shows a centered `Text("AcmeBank")` label on a plain SwiftUI screen.  
One XCTest asserts the view renders without crashing.

---

## Out of scope — deferred to future work

- **Okta OIDC authentication** (`AuthService`, `KeychainStore`, `UserSession`, `Okta.plist`) — future PR
- **Login screen & LoginCoordinator / LoginViewModel** — future PR
- **AppCoordinator + RootView auth-state switching** — future PR
- **URLSession networking layer** (`APIClient`, `APIRouter`, `APIError`, `RequestInterceptor`) — future PR
- **Domain models** (`Account`, `Transaction`, `Customer`, `TransferRequest`) — future PR
- **Repository protocols** (`AccountRepositoryProtocol`, `TransactionRepositoryProtocol`, `CustomerRepositoryProtocol`) — future PR
- **Remote API repositories** (`AccountAPIRepository`, `TransactionAPIRepository`, `CustomerAPIRepository`) — future PR
- **Mock data repositories** (`MockAccountRepository`, `MockTransactionRepository`, `MockCustomerRepository`) — future PR
- **Home screen** (`HomeView`, `HomeViewModel`, `HomeCoordinator`, sub-views) — future PR
- **Accounts, Transfer, Cards feature screens** — future PR
- **Design system** (`Colors.swift`, `Typography.swift`, `Assets.xcassets`) — future PR
- **NotificationCenter typed wrappers** (`AppNotification`, `NotificationPublisher`, `NotificationKey`) — future PR
- **TabBarCoordinator + full MVVM + Coordinator hierarchy** — future PR
- **XCUITest target + end-to-end UI tests** (Login, Transfer, Sign-Out flows) — future PR
- **CI workflow** (`ios-build.yml`, SwiftLint, xcconfig secret injection, warnings-as-errors) — future PR
- **`Localizable.strings` / `Info.plist` custom keys / `Okta.plist.example`** — future PR
