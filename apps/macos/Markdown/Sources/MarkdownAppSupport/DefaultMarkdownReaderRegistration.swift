import CoreServices
import Foundation

public enum DefaultMarkdownReaderRegistration {
    public static let markdownContentTypes = [
        "net.daringfireball.markdown",
    ]

    public static func makeDefaultReader(bundleIdentifier: String?) -> Result<Void, RegistrationError> {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return .failure(.missingBundleIdentifier)
        }

        for contentType in markdownContentTypes {
            let status = LSSetDefaultRoleHandlerForContentType(
                contentType as CFString,
                .viewer,
                bundleIdentifier as CFString
            )
            guard status == noErr else {
                return .failure(.launchServices(status: status))
            }
        }

        return .success(())
    }
}

public enum RegistrationError: Error, Equatable, Sendable {
    case missingBundleIdentifier
    case launchServices(status: OSStatus)

    public var userMessage: String {
        switch self {
        case .missingBundleIdentifier:
            return "Markdown could not find its app identifier."
        case .launchServices(let status):
            return "macOS could not update the default Markdown reader. Launch Services returned \(status)."
        }
    }
}
