import XCTest
import SwiftUI
@testable import AcmeBank

/// Bootstrap smoke test — proves the XCTest target links and runs.
/// Replace / extend with ViewModel unit tests as features are added.
final class ContentViewTests: XCTestCase {

    func test_contentView_instantiatesWithoutCrashing() {
        // Verify ContentView can be created — proves the SwiftUI entry point compiles.
        let view = ContentView()
        // Wrap in a hosting controller to trigger body evaluation.
        let host = UIHostingController(rootView: view)
        host.loadViewIfNeeded()
        XCTAssertNotNil(host.view, "ContentView should render a non-nil UIView")
    }
}
