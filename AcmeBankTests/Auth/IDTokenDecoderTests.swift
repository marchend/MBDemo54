import XCTest
@testable import AcmeBank

final class IDTokenDecoderTests: XCTestCase {

    // MARK: - Test helpers

    /// Base64url-encode arbitrary bytes (RFC 7515 §2): no padding, `-`/`_`
    /// instead of `+`/`/`.
    private func base64url(_ data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Build a JWT from a JSON payload object. Header and signature are
    /// fixed placeholders — the decoder ignores them.
    private func makeJWT(payload: [String: Any]) throws -> String {
        let headerJSON = try JSONSerialization.data(withJSONObject: ["alg": "RS256", "typ": "JWT"])
        let payloadJSON = try JSONSerialization.data(withJSONObject: payload)
        let header = base64url(headerJSON)
        let body = base64url(payloadJSON)
        let signature = base64url(Data("fake-signature".utf8))
        return "\(header).\(body).\(signature)"
    }

    // MARK: - Happy path

    func test_decode_extractsAllFourClaims() throws {
        let token = try makeJWT(payload: [
            "sub": "user-42",
            "name": "Alice Example",
            "email": "alice@example.com",
            "auth_time": 1_700_000_000
        ])

        let claims = try IDTokenDecoder.decode(token)

        XCTAssertEqual(claims.subject, "user-42")
        XCTAssertEqual(claims.name, "Alice Example")
        XCTAssertEqual(claims.email, "alice@example.com")
        XCTAssertEqual(claims.authTime, Date(timeIntervalSince1970: 1_700_000_000))
    }

    func test_decode_handlesMissingEmailGracefully() throws {
        let token = try makeJWT(payload: [
            "sub": "user-42",
            "name": "Alice Example",
            "auth_time": 1_700_000_000
        ])

        let claims = try IDTokenDecoder.decode(token)
        XCTAssertNil(claims.email)
        XCTAssertEqual(claims.subject, "user-42")
    }

    func test_decode_handlesMissingAuthTimeGracefully() throws {
        let token = try makeJWT(payload: [
            "sub": "user-42",
            "name": "Alice Example",
            "email": "alice@example.com"
        ])

        let claims = try IDTokenDecoder.decode(token)
        XCTAssertNil(claims.authTime)
        XCTAssertEqual(claims.email, "alice@example.com")
    }

    // MARK: - Malformed input

    func test_decode_rejectsNonThreeSegmentToken() {
        XCTAssertThrowsError(try IDTokenDecoder.decode("only.two")) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .malformedToken)
        }
        XCTAssertThrowsError(try IDTokenDecoder.decode("a.b.c.d")) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .malformedToken)
        }
        XCTAssertThrowsError(try IDTokenDecoder.decode("")) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .malformedToken)
        }
    }

    func test_decode_rejectsInvalidBase64Payload() {
        // `!!!` is not valid base64 / base64url characters.
        let token = "header.!!!.signature"
        XCTAssertThrowsError(try IDTokenDecoder.decode(token)) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .invalidBase64)
        }
    }

    func test_decode_rejectsNonJSONPayload() {
        let payload = self.base64url(Data("not json".utf8))
        let token = "header.\(payload).signature"
        XCTAssertThrowsError(try IDTokenDecoder.decode(token)) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .invalidJSON)
        }
    }

    func test_decode_rejectsMissingSubClaim() throws {
        let token = try makeJWT(payload: [
            "name": "Alice Example"
        ])
        XCTAssertThrowsError(try IDTokenDecoder.decode(token)) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .missingClaim("sub"))
        }
    }

    func test_decode_rejectsMissingNameClaim() throws {
        let token = try makeJWT(payload: [
            "sub": "user-42"
        ])
        XCTAssertThrowsError(try IDTokenDecoder.decode(token)) { error in
            XCTAssertEqual(error as? IDTokenDecodeError, .missingClaim("name"))
        }
    }
}
