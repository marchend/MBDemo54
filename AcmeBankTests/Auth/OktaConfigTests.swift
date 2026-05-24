import XCTest
@testable import AcmeBank

final class OktaConfigTests: XCTestCase {

    private var validDict: [String: Any] {
        [
            "OktaIssuer": "https://example.okta.com/oauth2/default",
            "OktaClientID": "0oaabc123",
            "OktaRedirectURI": "com.acmebank.mobile:/callback",
            "OktaScopes": "openid profile email offline_access"
        ]
    }

    // MARK: - Happy path

    func test_init_parsesAllFourKeys() throws {
        let cfg = try OktaConfig(infoDictionary: validDict)

        XCTAssertEqual(cfg.issuer.absoluteString, "https://example.okta.com/oauth2/default")
        XCTAssertEqual(cfg.clientID, "0oaabc123")
        XCTAssertEqual(cfg.redirectURI.absoluteString, "com.acmebank.mobile:/callback")
        XCTAssertEqual(cfg.scopes, ["openid", "profile", "email", "offline_access"])
    }

    func test_init_tolerates_extraWhitespaceInScopes() throws {
        var dict = validDict
        dict["OktaScopes"] = "  openid   profile  "
        let cfg = try OktaConfig(infoDictionary: dict)
        XCTAssertEqual(cfg.scopes, ["openid", "profile"])
    }

    // MARK: - Missing-key path

    func test_init_throwsMissingKey_whenIssuerAbsent() {
        var dict = validDict
        dict.removeValue(forKey: "OktaIssuer")
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey("OktaIssuer"))
        }
    }

    func test_init_throwsMissingKey_whenClientIDAbsent() {
        var dict = validDict
        dict.removeValue(forKey: "OktaClientID")
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey("OktaClientID"))
        }
    }

    func test_init_throwsMissingKey_whenRedirectURIAbsent() {
        var dict = validDict
        dict.removeValue(forKey: "OktaRedirectURI")
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey("OktaRedirectURI"))
        }
    }

    func test_init_throwsMissingKey_whenScopesAbsent() {
        var dict = validDict
        dict.removeValue(forKey: "OktaScopes")
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey("OktaScopes"))
        }
    }

    // MARK: - Empty-value path

    func test_init_throwsEmptyValue_whenIssuerBlank() {
        var dict = validDict
        dict["OktaIssuer"] = ""
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .emptyValue("OktaIssuer"))
        }
    }

    func test_init_throwsEmptyValue_whenClientIDIsWhitespace() {
        var dict = validDict
        dict["OktaClientID"] = "   "
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .emptyValue("OktaClientID"))
        }
    }

    // MARK: - Invalid URL path

    func test_init_throwsInvalidURL_whenIssuerNotParseable() {
        var dict = validDict
        // An empty string is rejected earlier (emptyValue), so use a value
        // that survives non-empty trimming but URL(string:) cannot parse.
        // URL is surprisingly permissive in Foundation; a string containing
        // a space yields nil.
        dict["OktaIssuer"] = "not a url"
        XCTAssertThrowsError(try OktaConfig(infoDictionary: dict)) { error in
            guard case let .invalidURL(key, _) = error as? OktaConfig.ConfigError else {
                XCTFail("expected invalidURL, got \(error)")
                return
            }
            XCTAssertEqual(key, "OktaIssuer")
        }
    }
}
