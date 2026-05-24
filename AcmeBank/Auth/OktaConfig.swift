import Foundation

/// Loads Okta tenant configuration from `Bundle.main.infoDictionary`.
///
/// The four keys (`OktaIssuer`, `OktaClientID`, `OktaRedirectURI`,
/// `OktaScopes`) are injected into the built `Info.plist` at build time by
/// `Scripts/inject-okta-config.sh` from the `OKTA_*` environment variables.
/// At runtime the app reads them via `Bundle.main.infoDictionary`.
///
/// The info dictionary is injectable so tests can drive both the happy path
/// and the missing-key path without touching the real bundle.
struct OktaConfig {

    // MARK: - Stored config

    let issuer: URL
    let clientID: String
    let redirectURI: URL
    let scopes: [String]

    // MARK: - Errors

    enum ConfigError: Error, LocalizedError, Equatable {
        case missingKey(String)
        case emptyValue(String)
        case invalidURL(key: String, value: String)

        var errorDescription: String? {
            switch self {
            case .missingKey(let key):
                return "Okta configuration is missing key '\(key)' in Info.plist."
            case .emptyValue(let key):
                return "Okta configuration key '\(key)' is empty in Info.plist."
            case .invalidURL(let key, let value):
                return "Okta configuration key '\(key)' is not a valid URL: '\(value)'."
            }
        }
    }

    // MARK: - Init

    /// Parse an Okta configuration from an arbitrary info dictionary.
    /// - Parameter infoDictionary: Typically `Bundle.main.infoDictionary`; tests
    ///   supply a synthetic dictionary.
    init(infoDictionary: [String: Any]) throws {
        let issuerString = try OktaConfig.requireString(infoDictionary, key: "OktaIssuer")
        let clientID = try OktaConfig.requireString(infoDictionary, key: "OktaClientID")
        let redirectURIString = try OktaConfig.requireString(infoDictionary, key: "OktaRedirectURI")
        let scopesString = try OktaConfig.requireString(infoDictionary, key: "OktaScopes")

        guard let issuer = URL(string: issuerString) else {
            throw ConfigError.invalidURL(key: "OktaIssuer", value: issuerString)
        }
        guard let redirectURI = URL(string: redirectURIString) else {
            throw ConfigError.invalidURL(key: "OktaRedirectURI", value: redirectURIString)
        }

        self.issuer = issuer
        self.clientID = clientID
        self.redirectURI = redirectURI
        // Scopes are stored as a single space-delimited string in Info.plist
        // (matching OAuth conventions). Tolerate multiple spaces / leading
        // / trailing whitespace.
        self.scopes = scopesString
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    /// Convenience: parse from a Bundle's info dictionary.
    init(bundle: Bundle) throws {
        try self.init(infoDictionary: bundle.infoDictionary ?? [:])
    }

    // MARK: - Live accessor

    /// Lazy app-wide accessor that reads from `Bundle.main`. Initialised on
    /// first use (Swift `static let` semantics), so accessing it from a
    /// context where the Info.plist isn't populated will crash with the
    /// underlying `ConfigError.errorDescription`. Tests must instantiate
    /// `OktaConfig(infoDictionary:)` directly instead of touching this.
    static let live: OktaConfig = {
        do {
            return try OktaConfig(bundle: .main)
        } catch {
            fatalError("OktaConfig failed to load from Bundle.main: \(error.localizedDescription)")
        }
    }()

    // MARK: - Helpers

    private static func requireString(_ dict: [String: Any], key: String) throws -> String {
        guard let raw = dict[key] else {
            throw ConfigError.missingKey(key)
        }
        guard let str = raw as? String else {
            throw ConfigError.missingKey(key)
        }
        let trimmed = str.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            throw ConfigError.emptyValue(key)
        }
        return trimmed
    }
}
