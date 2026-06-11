import Foundation

public struct RecentDocument: Identifiable, Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case file
        case folder
    }

    public let path: String
    public let kind: Kind
    public let lastOpenedAt: Date

    public var id: String { path }
    public var url: URL { URL(fileURLWithPath: path) }
    public var name: String { url.lastPathComponent.isEmpty ? path : url.lastPathComponent }

    public init(path: String, kind: Kind, lastOpenedAt: Date) {
        self.path = path
        self.kind = kind
        self.lastOpenedAt = lastOpenedAt
    }
}

public struct RestoredAppState: Codable, Equatable, Sendable {
    public var lastOpenedPath: String?
    public var selectedFilePath: String?
    public var expandedNodeIDs: [String]
    public var recentDocuments: [RecentDocument]
    public var leftSidebarWidth: Double
    public var rightOutlineWidth: Double
    public var isLeftSidebarVisible: Bool
    public var isOutlineVisible: Bool

    public static let empty = RestoredAppState(
        lastOpenedPath: nil,
        selectedFilePath: nil,
        expandedNodeIDs: [],
        recentDocuments: [],
        leftSidebarWidth: PaneLayout.defaultLeftSidebarWidth,
        rightOutlineWidth: PaneLayout.defaultRightOutlineWidth,
        isLeftSidebarVisible: true,
        isOutlineVisible: true
    )

    public init(
        lastOpenedPath: String?,
        selectedFilePath: String?,
        expandedNodeIDs: [String],
        recentDocuments: [RecentDocument],
        leftSidebarWidth: Double,
        rightOutlineWidth: Double,
        isLeftSidebarVisible: Bool,
        isOutlineVisible: Bool
    ) {
        self.lastOpenedPath = lastOpenedPath
        self.selectedFilePath = selectedFilePath
        self.expandedNodeIDs = expandedNodeIDs
        self.recentDocuments = recentDocuments
        self.leftSidebarWidth = PaneLayout.clampedLeftWidth(leftSidebarWidth)
        self.rightOutlineWidth = PaneLayout.clampedRightWidth(rightOutlineWidth)
        self.isLeftSidebarVisible = isLeftSidebarVisible
        self.isOutlineVisible = isOutlineVisible
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lastOpenedPath = try container.decodeIfPresent(String.self, forKey: .lastOpenedPath)
        selectedFilePath = try container.decodeIfPresent(String.self, forKey: .selectedFilePath)
        expandedNodeIDs = try container.decodeIfPresent([String].self, forKey: .expandedNodeIDs) ?? []
        recentDocuments = try container.decodeIfPresent([RecentDocument].self, forKey: .recentDocuments) ?? []
        leftSidebarWidth = PaneLayout.clampedLeftWidth(
            try container.decodeIfPresent(Double.self, forKey: .leftSidebarWidth) ?? PaneLayout.defaultLeftSidebarWidth
        )
        rightOutlineWidth = PaneLayout.clampedRightWidth(
            try container.decodeIfPresent(Double.self, forKey: .rightOutlineWidth) ?? PaneLayout.defaultRightOutlineWidth
        )
        isLeftSidebarVisible = try container.decodeIfPresent(Bool.self, forKey: .isLeftSidebarVisible) ?? true
        isOutlineVisible = try container.decodeIfPresent(Bool.self, forKey: .isOutlineVisible) ?? true
    }
}

public enum PaneLayout {
    public static let defaultLeftSidebarWidth = 300.0
    public static let minLeftSidebarWidth = 240.0
    public static let maxLeftSidebarWidth = 520.0

    public static let defaultRightOutlineWidth = 260.0
    public static let minRightOutlineWidth = 220.0
    public static let maxRightOutlineWidth = 420.0

    public static func clampedLeftWidth(_ width: Double) -> Double {
        min(max(width, minLeftSidebarWidth), maxLeftSidebarWidth)
    }

    public static func clampedRightWidth(_ width: Double) -> Double {
        min(max(width, minRightOutlineWidth), maxRightOutlineWidth)
    }
}

public final class AppSettings {
    private let defaults: UserDefaults
    private let stateKey = "Markdown.RestoredAppState.v1"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> RestoredAppState {
        guard let data = defaults.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(RestoredAppState.self, from: data)
        else {
            return .empty
        }
        return state
    }

    public func save(_ state: RestoredAppState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey)
    }
}
