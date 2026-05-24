import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// In-memory representation of the signed-in user.
///
/// Constructed from an `IDTokenClaims` plus the access token returned by the
/// OIDC token exchange. Codable so the app can persist it (e.g. for warm
/// re-launch) and round-trip it through tests.
struct UserSession: Codable, Equatable {
    let userId: String
    let displayName: String
    let email: String?
    let accessToken: String
    let authTimestamp: Date
    let deviceName: String

    init(
        userId: String,
        displayName: String,
        email: String?,
        accessToken: String,
        authTimestamp: Date,
        deviceName: String
    ) {
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.accessToken = accessToken
        self.authTimestamp = authTimestamp
        self.deviceName = deviceName
    }

    /// Convenience initializer that pulls `userId` / `displayName` / `email`
    /// out of `claims`, uses `claims.authTime` when present (falling back to
    /// `Date()`), and reads the device name from `UIDevice.current.name`.
    init(claims: IDTokenClaims, accessToken: String, deviceName: String = UserSession.currentDeviceName) {
        self.userId = claims.subject
        self.displayName = claims.name
        self.email = claims.email
        self.accessToken = accessToken
        self.authTimestamp = claims.authTime ?? Date()
        self.deviceName = deviceName
    }

    /// Device name resolution. Wrapped so tests on platforms without UIKit
    /// (or that want a deterministic value) can substitute it.
    static var currentDeviceName: String {
        #if canImport(UIKit)
        return UIDevice.current.name
        #else
        return "Unknown Device"
        #endif
    }
}
