import Foundation

struct PreviewAction: Equatable {
    enum Kind: Equatable {
        case jumpToAnchor(String)
        case findText(query: String, occurrence: Int)
    }

    let token: Int
    let kind: Kind
}
