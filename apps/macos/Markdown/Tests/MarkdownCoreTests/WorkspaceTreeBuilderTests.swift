import MarkdownCore
import XCTest

final class WorkspaceTreeBuilderTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
    }

    func testBuildsFolderTreeWithMarkdownFilesOnly() throws {
        try write("Root", to: tempDirectory.appendingPathComponent("README.md"))
        try write("Ignore", to: tempDirectory.appendingPathComponent("notes.txt"))
        try write("Hidden", to: tempDirectory.appendingPathComponent(".hidden.md"))

        let nested = tempDirectory.appendingPathComponent("Nested", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try write("Nested", to: nested.appendingPathComponent("Design.markdown"))

        let workspace = try WorkspaceTreeBuilder().build(from: tempDirectory)

        XCTAssertEqual(workspace.markdownFileCount, 2)
        XCTAssertEqual(workspace.root.children.map(\.name), ["Nested", "README.md"])
        XCTAssertEqual(workspace.root.children.first?.children.map(\.name), ["Design.markdown"])
    }

    func testBuildsSingleFileWorkspace() throws {
        let file = tempDirectory.appendingPathComponent("One.md")
        try write("# One", to: file)

        let workspace = try WorkspaceTreeBuilder().build(from: file)

        XCTAssertEqual(workspace.root.kind, .markdownFile)
        XCTAssertEqual(workspace.markdownFileCount, 1)
        XCTAssertEqual(workspace.folderCount, 0)
    }

    func testRejectsUnsupportedSingleFile() throws {
        let file = tempDirectory.appendingPathComponent("One.txt")
        try write("Nope", to: file)

        XCTAssertThrowsError(try WorkspaceTreeBuilder().build(from: file)) { error in
            XCTAssertEqual(error as? WorkspaceBuildError, .unsupportedFile(file.standardizedFileURL))
        }
    }

    func testSkipsSymbolicLinks() throws {
        let real = tempDirectory.appendingPathComponent("Real", isDirectory: true)
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        try write("Real", to: real.appendingPathComponent("Real.md"))

        let link = tempDirectory.appendingPathComponent("Link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        let workspace = try WorkspaceTreeBuilder().build(from: tempDirectory)

        XCTAssertEqual(workspace.markdownFileCount, 1)
        XCTAssertEqual(workspace.issues.count, 1)
        XCTAssertTrue(workspace.issues[0].message.contains("symbolic link"))
    }

    func testVisibleRowsFollowExpansionStateWithDepthAndParents() throws {
        try write("Root", to: tempDirectory.appendingPathComponent("README.md"))
        let notes = tempDirectory.appendingPathComponent("Notes", isDirectory: true)
        try FileManager.default.createDirectory(at: notes, withIntermediateDirectories: true)
        try write("Nested", to: notes.appendingPathComponent("Nested.md"))

        let workspace = try WorkspaceTreeBuilder().build(from: tempDirectory)
        let navigator = WorkspaceTreeNavigator()
        let collapsedRows = navigator.visibleRows(root: workspace.root, expandedNodeIDs: [])

        XCTAssertEqual(collapsedRows.map(\.name), [tempDirectory.lastPathComponent])
        XCTAssertEqual(collapsedRows[0].depth, 0)
        XCTAssertNil(collapsedRows[0].parentID)

        let notesID = workspace.root.children.first { $0.name == "Notes" }!.id
        let expandedRows = navigator.visibleRows(root: workspace.root, expandedNodeIDs: [workspace.root.id, notesID])

        XCTAssertEqual(expandedRows.map(\.name), [tempDirectory.lastPathComponent, "Notes", "Nested.md", "README.md"])
        XCTAssertEqual(expandedRows.map(\.depth), [0, 1, 2, 1])
        XCTAssertEqual(expandedRows.first { $0.name == "Nested.md" }?.parentID, notesID)
        XCTAssertEqual(expandedRows.first { $0.name == "README.md" }?.parentID, workspace.root.id)
    }

    func testNavigatorFindsNodeByID() throws {
        let notes = tempDirectory.appendingPathComponent("Notes", isDirectory: true)
        try FileManager.default.createDirectory(at: notes, withIntermediateDirectories: true)
        let nested = notes.appendingPathComponent("Nested.md")
        try write("Nested", to: nested)

        let workspace = try WorkspaceTreeBuilder().build(from: tempDirectory)
        let found = WorkspaceTreeNavigator().node(id: nested.standardizedFileURL.path, in: workspace.root)

        XCTAssertEqual(found?.name, "Nested.md")
        XCTAssertEqual(found?.kind, .markdownFile)
    }

    private func write(_ text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
