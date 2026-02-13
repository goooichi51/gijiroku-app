import Network

final class NetworkMonitor: Sendable {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool {
        monitor.currentPath.status == .satisfied
    }

    private init() {
        monitor.start(queue: queue)
    }
}
