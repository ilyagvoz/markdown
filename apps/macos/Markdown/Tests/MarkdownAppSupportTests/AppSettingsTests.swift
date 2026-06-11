import MarkdownAppSupport
import XCTest

final class AppSettingsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "MarkdownAppSupportTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testSavesAndLoadsPaneLayoutState() {
        let settings = AppSettings(defaults: defaults)
        let state = RestoredAppState(
            lastOpenedPath: "/tmp/workspace",
            selectedFilePath: "/tmp/workspace/readme.md",
            expandedNodeIDs: ["folder-a"],
            recentDocuments: [
                RecentDocument(path: "/tmp/workspace", kind: .folder, lastOpenedAt: Date(timeIntervalSince1970: 1_800))
            ],
            leftSidebarWidth: 378,
            rightOutlineWidth: 312,
            isLeftSidebarVisible: false,
            isOutlineVisible: true
        )

        settings.save(state)
        let loaded = settings.load()

        XCTAssertEqual(loaded.lastOpenedPath, "/tmp/workspace")
        XCTAssertEqual(loaded.selectedFilePath, "/tmp/workspace/readme.md")
        XCTAssertEqual(loaded.expandedNodeIDs, ["folder-a"])
        XCTAssertEqual(loaded.recentDocuments.map(\.path), ["/tmp/workspace"])
        XCTAssertEqual(loaded.leftSidebarWidth, 378)
        XCTAssertEqual(loaded.rightOutlineWidth, 312)
        XCTAssertFalse(loaded.isLeftSidebarVisible)
        XCTAssertTrue(loaded.isOutlineVisible)
    }

    func testDecodesOlderRestoredStateWithDefaultPaneLayout() throws {
        let legacyState = Data(
            """
            {
              "lastOpenedPath": "/tmp/workspace",
              "selectedFilePath": "/tmp/workspace/readme.md",
              "expandedNodeIDs": ["folder-a"],
              "recentDocuments": []
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(RestoredAppState.self, from: legacyState)

        XCTAssertEqual(decoded.leftSidebarWidth, PaneLayout.defaultLeftSidebarWidth)
        XCTAssertEqual(decoded.rightOutlineWidth, PaneLayout.defaultRightOutlineWidth)
        XCTAssertTrue(decoded.isLeftSidebarVisible)
        XCTAssertTrue(decoded.isOutlineVisible)
    }

    func testClampsPaneWidthsWhenStateIsCreatedOrDecoded() throws {
        let created = RestoredAppState(
            lastOpenedPath: nil,
            selectedFilePath: nil,
            expandedNodeIDs: [],
            recentDocuments: [],
            leftSidebarWidth: 12,
            rightOutlineWidth: 999,
            isLeftSidebarVisible: true,
            isOutlineVisible: true
        )

        XCTAssertEqual(created.leftSidebarWidth, PaneLayout.minLeftSidebarWidth)
        XCTAssertEqual(created.rightOutlineWidth, PaneLayout.maxRightOutlineWidth)

        let encoded = Data(
            """
            {
              "expandedNodeIDs": [],
              "recentDocuments": [],
              "leftSidebarWidth": 999,
              "rightOutlineWidth": 12,
              "isLeftSidebarVisible": true,
              "isOutlineVisible": true
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(RestoredAppState.self, from: encoded)

        XCTAssertEqual(decoded.leftSidebarWidth, PaneLayout.maxLeftSidebarWidth)
        XCTAssertEqual(decoded.rightOutlineWidth, PaneLayout.minRightOutlineWidth)
    }
}
