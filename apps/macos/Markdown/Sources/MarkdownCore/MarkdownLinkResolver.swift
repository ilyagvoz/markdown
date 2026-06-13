import Foundation

public enum MarkdownLinkDestination: Equatable, Sendable {
    case markdownFile(fileURL: URL, fragment: String?)
    case externalURL(URL)
    case unsupported(URL?)
}

public struct MarkdownLinkResolver {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func resolve(
        href: String,
        resolvedHref: String? = nil,
        documentURL: URL
    ) -> MarkdownLinkDestination {
        let trimmedHref = href.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHref.isEmpty else {
            return .unsupported(nil)
        }

        if trimmedHref.hasPrefix("#") {
            return localMarkdownDestination(
                for: documentURL,
                fragment: fragment(fromRawHash: trimmedHref)
            )
        }

        guard let url = absoluteURL(
            href: trimmedHref,
            resolvedHref: resolvedHref,
            documentURL: documentURL
        ) else {
            return .unsupported(nil)
        }

        if url.isFileURL {
            return localMarkdownDestination(for: url, fragment: url.fragment)
        }

        switch url.scheme?.lowercased() {
        case "http", "https":
            return .externalURL(url)
        default:
            return .unsupported(url)
        }
    }

    private func absoluteURL(href: String, resolvedHref: String?, documentURL: URL) -> URL? {
        if let resolvedHref,
           !resolvedHref.isEmpty,
           let resolvedURL = URL(string: resolvedHref) {
            return resolvedURL.absoluteURL
        }

        if let directURL = URL(string: href), directURL.scheme != nil {
            return directURL.absoluteURL
        }

        if href.hasPrefix("/") {
            return URL(fileURLWithPath: href).absoluteURL
        }

        return URL(string: href, relativeTo: documentURL.deletingLastPathComponent())?.absoluteURL
    }

    private func localMarkdownDestination(for url: URL, fragment: String?) -> MarkdownLinkDestination {
        let fileURL = fileURLWithoutFragmentOrQuery(url)
        guard let markdownURL = existingMarkdownURL(for: fileURL) else {
            return .unsupported(fileURL)
        }
        return .markdownFile(fileURL: markdownURL, fragment: normalizedFragment(fragment))
    }

    private func fileURLWithoutFragmentOrQuery(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url.standardizedFileURL
        }
        components.fragment = nil
        components.query = nil
        return components.url?.standardizedFileURL ?? url.standardizedFileURL
    }

    private func existingMarkdownURL(for url: URL) -> URL? {
        let standardized = url.standardizedFileURL
        if isExistingMarkdownFile(standardized) {
            return standardized
        }

        guard standardized.pathExtension.isEmpty else {
            return nil
        }

        for pathExtension in ["md", "markdown"] {
            let candidate = standardized.appendingPathExtension(pathExtension)
            if isExistingMarkdownFile(candidate) {
                return candidate.standardizedFileURL
            }
        }

        return nil
    }

    private func isExistingMarkdownFile(_ url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        guard pathExtension == "md" || pathExtension == "markdown" else {
            return false
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        return !isDirectory.boolValue
    }

    private func fragment(fromRawHash value: String) -> String? {
        guard value.hasPrefix("#") else {
            return nil
        }
        return normalizedFragment(String(value.dropFirst()))
    }

    private func normalizedFragment(_ value: String?) -> String? {
        guard let value,
              !value.isEmpty
        else {
            return nil
        }
        return value.removingPercentEncoding ?? value
    }
}
