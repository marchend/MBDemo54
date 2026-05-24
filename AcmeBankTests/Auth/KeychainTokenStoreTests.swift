import XCTest
@testable import AcmeBank

final class KeychainTokenStoreTests: XCTestCase {

    private var store: KeychainTokenStore!
    private var service: String!

    override func setUp() {
        super.setUp()
        // Unique service per test so cases don't see each other's items
        // and we don't collide with whatever the simulator already has.
        service = "com.acmebank.mobile.tests.\(UUID().uuidString)"
        store = KeychainTokenStore(service: service)
    }

    override func tearDown() {
        try? store.clearAll()
        store = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Round trip

    func test_setAndGet_accessToken() throws {
        try store.setAccessToken("access-abc")
        XCTAssertEqual(try store.accessToken(), "access-abc")
    }

    func test_setAndGet_idToken() throws {
        try store.setIDToken("id-xyz")
        XCTAssertEqual(try store.idToken(), "id-xyz")
    }

    func test_setAndGet_refreshToken() throws {
        try store.setRefreshToken("refresh-123")
        XCTAssertEqual(try store.refreshToken(), "refresh-123")
    }

    func test_set_overwritesExistingValue() throws {
        try store.setAccessToken("first")
        try store.setAccessToken("second")
        XCTAssertEqual(try store.accessToken(), "second")
    }

    // MARK: - Absent values

    func test_get_returnsNilWhenAbsent() throws {
        XCTAssertNil(try store.accessToken())
        XCTAssertNil(try store.idToken())
        XCTAssertNil(try store.refreshToken())
    }

    func test_setRefreshToken_nilDeletesExistingValue() throws {
        try store.setRefreshToken("refresh-123")
        XCTAssertEqual(try store.refreshToken(), "refresh-123")

        try store.setRefreshToken(nil)
        XCTAssertNil(try store.refreshToken())
    }

    func test_setRefreshToken_nilWhenAbsentIsNoop() throws {
        // Should not throw even though there's nothing to delete.
        XCTAssertNoThrow(try store.setRefreshToken(nil))
        XCTAssertNil(try store.refreshToken())
    }

    // MARK: - clearAll

    func test_clearAll_removesAllThreeTokens() throws {
        try store.setAccessToken("a")
        try store.setIDToken("i")
        try store.setRefreshToken("r")

        try store.clearAll()

        XCTAssertNil(try store.accessToken())
        XCTAssertNil(try store.idToken())
        XCTAssertNil(try store.refreshToken())
    }

    func test_clearAll_isIdempotent() throws {
        try store.clearAll()
        XCTAssertNoThrow(try store.clearAll())
    }

    // MARK: - Isolation

    func test_separateServiceIDs_doNotShareState() throws {
        let other = KeychainTokenStore(service: "com.acmebank.mobile.tests.\(UUID().uuidString)")
        defer { try? other.clearAll() }

        try store.setAccessToken("ours")
        XCTAssertNil(try other.accessToken(), "Items must be scoped by service identifier")
    }
}
