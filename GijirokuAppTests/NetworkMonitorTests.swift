import XCTest
@testable import GijirokuApp

final class NetworkMonitorTests: XCTestCase {

    func testSharedInstanceExists() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor)
    }

    func testSharedInstanceIsSingleton() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared
        XCTAssertTrue(monitor1 === monitor2)
    }

    func testIsConnectedReturnsBoolean() {
        let monitor = NetworkMonitor.shared
        _ = monitor.isConnected
    }
}
