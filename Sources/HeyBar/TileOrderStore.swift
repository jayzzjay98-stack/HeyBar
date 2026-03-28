import Foundation

enum TileID: String, CaseIterable {
        case keepAwake, hiddenFiles, fileExtensions
    case keyLight, nightShift, hideDock, hideBar, cleanKey, showDesktop
}

@MainActor
final class TileOrderStore {
    static let shared = TileOrderStore()
    static let didChangeNotification = Notification.Name("com.gravity.heybar.tileOrderDidChange")

    private let orderKey  = "com.gravity.heybar.tileOrder"
    private let hiddenKey = "com.gravity.heybar.hiddenTiles"

    private(set) var order: [TileID]
    private(set) var hidden: Set<TileID>

    private init() {
        let raw = UserDefaults.standard.array(forKey: orderKey) as? [String] ?? []
        let decoded = raw.compactMap(TileID.init(rawValue:))
        let missing = TileID.allCases.filter { !decoded.contains($0) }
        order = decoded + missing

        let hiddenRaw = UserDefaults.standard.array(forKey: hiddenKey) as? [String] ?? []
        hidden = Set(hiddenRaw.compactMap(TileID.init(rawValue:)))
    }

    func setHidden(_ id: TileID, _ value: Bool) {
        if value { hidden.insert(id) } else { hidden.remove(id) }
        persist()
    }

    func setOrder(_ newOrder: [TileID]) {
        order = newOrder
        persist()
    }

    func reload() {
        let raw = UserDefaults.standard.array(forKey: orderKey) as? [String] ?? []
        let decoded = raw.compactMap(TileID.init(rawValue:))
        let missing = TileID.allCases.filter { !decoded.contains($0) }
        order = decoded + missing

        let hiddenRaw = UserDefaults.standard.array(forKey: hiddenKey) as? [String] ?? []
        hidden = Set(hiddenRaw.compactMap(TileID.init(rawValue:)))
    }

    private func persist() {
        UserDefaults.standard.set(order.map(\.rawValue), forKey: orderKey)
        UserDefaults.standard.set(Array(hidden).map(\.rawValue), forKey: hiddenKey)
        DistributedNotificationCenter.default().postNotificationName(
            Self.didChangeNotification,
            object: Bundle.main.bundleIdentifier,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
