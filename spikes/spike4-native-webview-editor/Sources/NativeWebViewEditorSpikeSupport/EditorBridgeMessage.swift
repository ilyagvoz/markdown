import Foundation

public enum EditorBridgeMessageType: String, Codable, Equatable, Sendable {
    case ready
    case documentChanged
    case blockUnlocked
    case shortcut
    case saveRequested
}

public struct EditorBridgeMessage: Codable, Equatable, Sendable {
    public let type: EditorBridgeMessageType
    public let markdown: String?
    public let blockID: String?
    public let route: String?
    public let key: String?

    public init(type: EditorBridgeMessageType, markdown: String? = nil, blockID: String? = nil, route: String? = nil, key: String? = nil) {
        self.type = type
        self.markdown = markdown
        self.blockID = blockID
        self.route = route
        self.key = key
    }
}

public enum EditorBridgeMessageParser {
    public static func parse(_ body: Any) -> EditorBridgeMessage? {
        guard JSONSerialization.isValidJSONObject(body),
              let data = try? JSONSerialization.data(withJSONObject: body),
              let message = try? JSONDecoder().decode(EditorBridgeMessage.self, from: data)
        else {
            return nil
        }
        return message
    }

    public static func statusText(for message: EditorBridgeMessage) -> String {
        switch message.type {
        case .ready:
            return "Editor ready"
        case .documentChanged:
            let byteCount = message.markdown?.utf8.count ?? 0
            return "Document changed (\(byteCount) bytes)"
        case .blockUnlocked:
            return "Unlocked \(message.blockID ?? "block")"
        case .shortcut:
            return "Shortcut \(message.key ?? "?") routed to \(message.route ?? "unknown")"
        case .saveRequested:
            let byteCount = message.markdown?.utf8.count ?? 0
            return "Save requested (\(byteCount) bytes)"
        }
    }
}
