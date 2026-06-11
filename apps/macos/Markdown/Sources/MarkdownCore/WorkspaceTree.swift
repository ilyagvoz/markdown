import Foundation

public enum WorkspaceNodeKind: String, Sendable {
    case folder
    case markdownFile
}

public struct WorkspaceNode: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let url: URL
    public let kind: WorkspaceNodeKind
    public var children: [WorkspaceNode]

    public init(name: String, url: URL, kind: WorkspaceNodeKind, children: [WorkspaceNode] = []) {
        self.name = name
        self.url = url
        self.kind = kind
        self.children = children
        self.id = url.standardizedFileURL.path
    }

    public var isFolder: Bool {
        kind == .folder
    }
}

public struct Workspace: Equatable, Sendable {
    public let rootURL: URL
    public let root: WorkspaceNode
    public let markdownFileCount: Int
    public let folderCount: Int
    public let issues: [WorkspaceScanIssue]

    public init(rootURL: URL, root: WorkspaceNode, markdownFileCount: Int, folderCount: Int, issues: [WorkspaceScanIssue]) {
        self.rootURL = rootURL
        self.root = root
        self.markdownFileCount = markdownFileCount
        self.folderCount = folderCount
        self.issues = issues
    }
}

public struct WorkspaceScanIssue: Equatable, Sendable {
    public let url: URL
    public let message: String

    public init(url: URL, message: String) {
        self.url = url
        self.message = message
    }
}

public enum WorkspaceBuildError: LocalizedError, Equatable {
    case unsupportedFile(URL)
    case missingResource(URL)
    case unreadableResource(URL)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedFile(url):
            return "\(url.lastPathComponent) is not a Markdown file or folder."
        case let .missingResource(url):
            return "\(url.path) does not exist."
        case let .unreadableResource(url):
            return "\(url.path) is not readable."
        }
    }
}

public struct WorkspaceTreeBuilder {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func build(from url: URL) throws -> Workspace {
        let standardized = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: standardized.path, isDirectory: &isDirectory) else {
            throw WorkspaceBuildError.missingResource(standardized)
        }

        guard fileManager.isReadableFile(atPath: standardized.path) else {
            throw WorkspaceBuildError.unreadableResource(standardized)
        }

        if !isDirectory.boolValue {
            guard Self.isMarkdownFile(standardized) else {
                throw WorkspaceBuildError.unsupportedFile(standardized)
            }
            let node = WorkspaceNode(name: standardized.lastPathComponent, url: standardized, kind: .markdownFile)
            return Workspace(rootURL: standardized, root: node, markdownFileCount: 1, folderCount: 0, issues: [])
        }

        var issues: [WorkspaceScanIssue] = []
        var visitedDirectories = Set<String>()
        let root = scanDirectory(standardized, issues: &issues, visitedDirectories: &visitedDirectories)
        let counts = count(root)
        return Workspace(
            rootURL: standardized,
            root: root,
            markdownFileCount: counts.files,
            folderCount: counts.folders,
            issues: issues
        )
    }

    public static func isMarkdownFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "md" || ext == "markdown"
    }

    private func scanDirectory(
        _ directory: URL,
        issues: inout [WorkspaceScanIssue],
        visitedDirectories: inout Set<String>
    ) -> WorkspaceNode {
        let standardized = directory.standardizedFileURL
        let realPath = (try? fileManager.destinationOfSymbolicLink(atPath: standardized.path)).map { path in
            URL(fileURLWithPath: path, relativeTo: standardized.deletingLastPathComponent()).standardizedFileURL.path
        } ?? standardized.path

        guard !visitedDirectories.contains(realPath) else {
            issues.append(WorkspaceScanIssue(url: standardized, message: "Skipped symlink cycle."))
            return WorkspaceNode(name: displayName(for: standardized), url: standardized, kind: .folder)
        }
        visitedDirectories.insert(realPath)

        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey, .isSymbolicLinkKey]
        let entries: [URL]
        do {
            entries = try fileManager.contentsOfDirectory(
                at: standardized,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsPackageDescendants]
            )
        } catch {
            issues.append(WorkspaceScanIssue(url: standardized, message: error.localizedDescription))
            return WorkspaceNode(name: displayName(for: standardized), url: standardized, kind: .folder)
        }

        var childNodes: [WorkspaceNode] = []
        for entry in entries where shouldConsider(entry) {
            do {
                let values = try entry.resourceValues(forKeys: Set(resourceKeys))
                if values.isHidden == true || entry.lastPathComponent.hasPrefix(".") {
                    continue
                }
                if values.isSymbolicLink == true {
                    issues.append(WorkspaceScanIssue(url: entry, message: "Skipped symbolic link."))
                    continue
                }
                if values.isDirectory == true {
                    childNodes.append(scanDirectory(entry, issues: &issues, visitedDirectories: &visitedDirectories))
                } else if Self.isMarkdownFile(entry) {
                    childNodes.append(WorkspaceNode(name: entry.lastPathComponent, url: entry.standardizedFileURL, kind: .markdownFile))
                }
            } catch {
                issues.append(WorkspaceScanIssue(url: entry, message: error.localizedDescription))
            }
        }

        childNodes.sort { left, right in
            if left.kind != right.kind {
                return left.kind == .folder
            }
            return left.name.localizedStandardCompare(right.name) == .orderedAscending
        }

        return WorkspaceNode(
            name: displayName(for: standardized),
            url: standardized,
            kind: .folder,
            children: childNodes
        )
    }

    private func shouldConsider(_ url: URL) -> Bool {
        !url.lastPathComponent.isEmpty
    }

    private func displayName(for url: URL) -> String {
        let name = url.lastPathComponent
        return name.isEmpty ? url.path : name
    }

    private func count(_ node: WorkspaceNode) -> (files: Int, folders: Int) {
        var files = node.kind == .markdownFile ? 1 : 0
        var folders = node.kind == .folder ? 1 : 0
        for child in node.children {
            let childCount = count(child)
            files += childCount.files
            folders += childCount.folders
        }
        return (files, folders)
    }
}
