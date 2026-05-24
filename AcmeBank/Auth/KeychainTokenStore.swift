import Foundation
import Security

/// Abstraction over the three Okta tokens the app persists.
///
/// `refreshToken` is optional because not all Okta configurations issue one,
/// and `clearAll()` removes every entry regardless of which were set.
protocol TokenStore {
    func setAccessToken(_ token: String) throws
    func accessToken() throws -> String?
    func setIDToken(_ token: String) throws
    func idToken() throws -> String?
    func setRefreshToken(_ token: String?) throws
    func refreshToken() throws -> String?
    func clearAll() throws
}

/// Keychain-backed implementation of `TokenStore`.
///
/// Each token is stored as a separate generic-password item under the same
/// service identifier, distinguished by `account`. Items use
/// `kSecAttrAccessibleAfterFirstUnlock` so the app can refresh tokens in the
/// background after first device unlock without prompting biometrics.
///
/// The service identifier is injectable so tests can scope to a unique value
/// per test and avoid polluting the shared simulator keychain.
final class KeychainTokenStore: TokenStore {

    // MARK: - Account keys (distinguish the three tokens within the service)

    private enum Account {
        static let access = "accessToken"
        static let id = "idToken"
        static let refresh = "refreshToken"
        static let all: [String] = [access, id, refresh]
    }

    enum KeychainError: Error, Equatable {
        case unexpectedStatus(OSStatus)
        case dataConversion
    }

    // MARK: - Stored config

    let service: String

    /// - Parameter service: Keychain service identifier. Defaults to
    ///   `Bundle.main.bundleIdentifier ?? "com.acmebank.mobile"`. Tests pass
    ///   a unique value (e.g. a UUID) to isolate from other tests and from
    ///   any previous simulator state.
    init(service: String = Bundle.main.bundleIdentifier ?? "com.acmebank.mobile") {
        self.service = service
    }

    // MARK: - TokenStore

    func setAccessToken(_ token: String) throws {
        try set(token, account: Account.access)
    }

    func accessToken() throws -> String? {
        try get(account: Account.access)
    }

    func setIDToken(_ token: String) throws {
        try set(token, account: Account.id)
    }

    func idToken() throws -> String? {
        try get(account: Account.id)
    }

    func setRefreshToken(_ token: String?) throws {
        if let token = token {
            try set(token, account: Account.refresh)
        } else {
            try delete(account: Account.refresh)
        }
    }

    func refreshToken() throws -> String? {
        try get(account: Account.refresh)
    }

    func clearAll() throws {
        for account in Account.all {
            try delete(account: account)
        }
    }

    // MARK: - Keychain helpers

    private func baseQuery(account: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func set(_ value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataConversion
        }

        // Try to update an existing item first; if none exists, add a new one.
        let query = baseQuery(account: account)
        let updateAttrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus != errSecSuccess {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(updateStatus)
        }
    }

    private func get(account: String) throws -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.dataConversion
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func delete(account: String) throws {
        let query = baseQuery(account: account)
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
