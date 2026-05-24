import XCTest
@testable import AcmeBank

final class UserSessionTests: XCTestCase {

    // MARK: - Codable round trip

    func test_codable_roundTrip_preservesAllFields() throws {
        let original = UserSession(
            userId: "user-42",
            displayName: "Alice Example",
            email: "alice@example.com",
            accessToken: "access-token-abc",
            authTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Alice's iPhone"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserSession.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func test_codable_roundTrip_preservesNilEmail() throws {
        let original = UserSession(
            userId: "user-42",
            displayName: "Alice Example",
            email: nil,
            accessToken: "access-token-abc",
            authTimestamp: Date(timeIntervalSince1970: 1_700_000_000),
            deviceName: "Alice's iPhone"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserSession.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertNil(decoded.email)
    }

    // MARK: - Construction from IDTokenClaims

    func test_init_fromClaims_copiesFieldsAcross() {
        let authTime = Date(timeIntervalSince1970: 1_700_000_000)
        let claims = IDTokenClaims(
            subject: "user-42",
            name: "Alice Example",
            email: "alice@example.com",
            authTime: authTime
        )

        let session = UserSession(
            claims: claims,
            accessToken: "access-token-abc",
            deviceName: "Alice's iPhone"
        )

        XCTAssertEqual(session.userId, "user-42")
        XCTAssertEqual(session.displayName, "Alice Example")
        XCTAssertEqual(session.email, "alice@example.com")
        XCTAssertEqual(session.accessToken, "access-token-abc")
        XCTAssertEqual(session.authTimestamp, authTime)
        XCTAssertEqual(session.deviceName, "Alice's iPhone")
    }

    func test_init_fromClaims_fallsBackToNowWhenAuthTimeAbsent() {
        let claims = IDTokenClaims(
            subject: "user-42",
            name: "Alice Example",
            email: nil,
            authTime: nil
        )

        let before = Date()
        let session = UserSession(
            claims: claims,
            accessToken: "access-token-abc",
            deviceName: "Test Device"
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(session.authTimestamp, before.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(session.authTimestamp, after.addingTimeInterval(1))
        XCTAssertNil(session.email)
    }

    func test_init_fromClaims_defaultDeviceNameIsNonEmpty() {
        let claims = IDTokenClaims(
            subject: "user-42",
            name: "Alice Example",
            email: nil,
            authTime: nil
        )

        let session = UserSession(claims: claims, accessToken: "tok")
        XCTAssertFalse(session.deviceName.isEmpty, "deviceName must come from UIDevice.current.name and never be empty")
    }
}
