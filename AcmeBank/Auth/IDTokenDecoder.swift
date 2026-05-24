import Foundation

/// Claims extracted from an Okta-issued OIDC ID token.
///
/// Only the four fields AcmeBank's domain model needs (`sub`, `name`,
/// `email`, `auth_time`) are surfaced. `email` and `auth_time` are optional
/// because Okta tenants vary in which scopes / claims they include.
struct IDTokenClaims: Equatable {
    let subject: String
    let name: String
    let email: String?
    let authTime: Date?
}

enum IDTokenDecodeError: Error, Equatable {
    /// The token does not have the three `header.payload.signature` segments.
    case malformedToken
    /// The payload segment is not valid base64url-encoded data.
    case invalidBase64
    /// The decoded payload is not a JSON object.
    case invalidJSON
    /// A required claim (`sub` or `name`) is absent.
    case missingClaim(String)
}

/// Decodes the payload section of a JWT and extracts the AcmeBank claim set.
///
/// The signature is **not** verified here — that's the Okta SDK's job during
/// the token exchange. This decoder only consumes a token the SDK already
/// vouched for and lifts the claims into Swift types.
enum IDTokenDecoder {

    static func decode(_ token: String) throws -> IDTokenClaims {
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            throw IDTokenDecodeError.malformedToken
        }

        let payloadSegment = String(segments[1])
        guard let payloadData = base64urlDecode(payloadSegment) else {
            throw IDTokenDecodeError.invalidBase64
        }

        guard let json = try? JSONSerialization.jsonObject(with: payloadData, options: []),
              let dict = json as? [String: Any] else {
            throw IDTokenDecodeError.invalidJSON
        }

        guard let subject = dict["sub"] as? String, !subject.isEmpty else {
            throw IDTokenDecodeError.missingClaim("sub")
        }
        guard let name = dict["name"] as? String, !name.isEmpty else {
            throw IDTokenDecodeError.missingClaim("name")
        }

        let email = dict["email"] as? String

        let authTime: Date?
        if let secs = dict["auth_time"] as? TimeInterval {
            authTime = Date(timeIntervalSince1970: secs)
        } else if let secsInt = dict["auth_time"] as? Int {
            authTime = Date(timeIntervalSince1970: TimeInterval(secsInt))
        } else {
            authTime = nil
        }

        return IDTokenClaims(
            subject: subject,
            name: name,
            email: email,
            authTime: authTime
        )
    }

    // MARK: - base64url

    /// Decode a base64url-encoded string (RFC 7515 §2). JWTs use the URL-safe
    /// variant without padding, so we restore the alphabet and re-pad to a
    /// multiple of 4 before handing off to `Data(base64Encoded:)`.
    static func base64urlDecode(_ input: String) -> Data? {
        var s = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad to multiple of 4.
        let remainder = s.count % 4
        if remainder > 0 {
            s.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: s)
    }
}
