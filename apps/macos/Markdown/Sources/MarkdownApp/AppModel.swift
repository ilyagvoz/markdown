import AppKit
import Combine
import Foundation
import MarkdownAppSupport
import MarkdownCore

@MainActor
final class AppModel: ObservableObject {
    enum PreviewState: Equatable {
        case empty
        case loading(String)
        case rendered(fileURL: URL, title: String, markdown: String, html: String)
        case failure(String)
    }

    @Published private(set) var workspace: Workspace?
    @Published private(set) var selectedFileURL: URL?
    @Published private(set) var sidebarSelectionID: String?
    @Published private(set) var previewState: PreviewState = .empty
    @Published private(set) var statusText = "Open a Markdown file or folder"
    @Published private(set) var resourceText = ""
    @Published private(set) var hoveredLinkDestination: String?
    @Published private(set) var canNavigateBack = false
    @Published private(set) var canNavigateForward = false
    @Published private(set) var recentDocuments: [RecentDocument] = []
    @Published private(set) var documentOutline: [DocumentOutlineItem] = []
    @Published private(set) var searchResults: [DocumentSearchResult] = []
    @Published private(set) var workspaceSearchResults: [WorkspaceSearchResult] = []
    @Published private(set) var isWorkspaceSearchRunning = false
    @Published private(set) var pendingPreviewAction: PreviewAction?
    @Published private(set) var isDocumentDirty = false
    @Published var searchQuery = "" {
        didSet { updateSearchResults() }
    }
    @Published var isSearchVisible = false
    @Published var isLeftSidebarVisible = true {
        didSet {
            guard !isApplyingRestoredState else { return }
            persistState()
        }
    }
    @Published var isOutlineVisible = true {
        didSet {
            guard !isApplyingRestoredState else { return }
            persistState()
        }
    }
    @Published var isShortcutHelpPresented = false
    @Published var leftSidebarWidth = PaneLayout.defaultLeftSidebarWidth {
        didSet {
            let clamped = PaneLayout.clampedLeftWidth(leftSidebarWidth)
            if clamped != leftSidebarWidth {
                leftSidebarWidth = clamped
                return
            }
            guard !isApplyingRestoredState else { return }
            persistState()
        }
    }
    @Published var rightOutlineWidth = PaneLayout.defaultRightOutlineWidth {
        didSet {
            let clamped = PaneLayout.clampedRightWidth(rightOutlineWidth)
            if clamped != rightOutlineWidth {
                rightOutlineWidth = clamped
                return
            }
            guard !isApplyingRestoredState else { return }
            persistState()
        }
    }
    @Published var expandedNodeIDs = Set<String>() {
        didSet {
            guard !isApplyingRestoredState else { return }
            persistState()
        }
    }

    private let treeBuilder = WorkspaceTreeBuilder()
    private let treeNavigator = WorkspaceTreeNavigator()
    private let renderer = MarkdownHTMLRenderer()
    private let analyzer = MarkdownDocumentAnalyzer()
    private let linkResolver = MarkdownLinkResolver()
    private let settings = AppSettings()
    private let selectedFileWatcher = FileWatcher()
    private let directoryWatcher = DirectoryWatcher()
    private let shortcutMonitor = KeyboardShortcutMonitor()
    private let resourceSampler = ProcessResourceSampler()
    private var restoredState = RestoredAppState.empty
    private var lastOpenedURL: URL?
    private var hasPreparedAppState = false
    private var hasRestoredInitialState = false
    private var currentMarkdown = ""
    private var previewActionToken = 0
    private var resourceTimer: Timer?
    private var resourceSampleTask: Task<Void, Never>?
    private var workspaceSearchTask: Task<Void, Never>?
    private var autosaveTask: Task<Void, Never>?
    private var isApplyingRestoredState = false
    private var lastSidebarClickID: String?
    private var lastSidebarClickAt: Date?
    private let sidebarRenameDelay: TimeInterval = 0.55
    private let autosaveDelay: Duration = .milliseconds(1_500)
    private var navigationBackStack: [NavigationLocation] = [] {
        didSet { updateNavigationAvailability() }
    }
    private var navigationForwardStack: [NavigationLocation] = [] {
        didSet { updateNavigationAvailability() }
    }

    enum NavigationHistoryPolicy {
        case reset
        case preserve
    }

    private struct NavigationLocation: Equatable {
        let openedURL: URL
        let selectedFileURL: URL?
    }

    func openLaunchArgumentIfPresent() async {
        prepareAppStateIfNeeded()

        let arguments = CommandLine.arguments
        if let openIndex = arguments.firstIndex(of: "--open"),
           arguments.indices.contains(openIndex + 1) {
            hasRestoredInitialState = true
            await open(url: URL(fileURLWithPath: arguments[openIndex + 1]))
            return
        }

        guard !hasRestoredInitialState else { return }
        hasRestoredInitialState = true

        if let path = restoredState.lastOpenedPath, FileManager.default.fileExists(atPath: path) {
            await open(url: URL(fileURLWithPath: path), preferredSelectedFile: restoredState.selectedFilePath.map(URL.init(fileURLWithPath:)))
        } else {
            sampleResourcesIfVisible()
        }
    }

    func openExternalURLs(_ urls: [URL]) async {
        prepareAppStateIfNeeded()

        guard let url = preferredExternalOpenURL(from: urls) else {
            sampleResourcesIfVisible()
            return
        }

        hasRestoredInitialState = true
        await open(url: url)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "Open Markdown"
        panel.message = "Choose a Markdown file or a folder."
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                await self?.open(url: url)
            }
        }
    }

    func clearRecents() {
        recentDocuments = []
        persistState()
    }

    func openRecent(_ recent: RecentDocument) async {
        await open(url: recent.url)
    }

    func open(
        url: URL,
        preferredSelectedFile: URL? = nil,
        historyPolicy: NavigationHistoryPolicy = .reset
    ) async {
        if historyPolicy == .reset {
            resetLinkNavigationHistory()
        }
        hoveredLinkDestination = nil
        flushAutosaveIfNeeded()
        statusText = "Opening \(url.lastPathComponent)..."
        previewState = .loading(url.lastPathComponent)

        do {
            let workspace = try treeBuilder.build(from: url)
            self.workspace = workspace
            lastOpenedURL = url.standardizedFileURL
            rememberRecent(url: url, workspace: workspace)
            statusText = status(for: workspace)
            restoreExpandedNodesIfPossible(for: workspace)
            watchDirectories(in: workspace)

            if workspace.root.kind == .markdownFile {
                await selectFile(workspace.root.url, historyPolicy: historyPolicy)
            } else if let preferredSelectedFile,
                      containsFile(preferredSelectedFile, in: workspace.root) {
                await selectFile(preferredSelectedFile, historyPolicy: historyPolicy)
            } else if let first = firstMarkdownFile(in: workspace.root) {
                await selectFile(first.url, historyPolicy: historyPolicy)
            } else {
                selectedFileURL = nil
                sidebarSelectionID = workspace.root.id
                previewState = .empty
                selectedFileWatcher.stop()
                documentOutline = []
                currentMarkdown = ""
                searchResults = []
                workspaceSearchResults = []
                statusText = "\(workspace.root.name) has no Markdown files"
                persistState()
            }
        } catch {
            workspace = nil
            selectedFileURL = nil
            sidebarSelectionID = nil
            previewState = .failure(error.localizedDescription)
            selectedFileWatcher.stop()
            directoryWatcher.stop()
            documentOutline = []
            currentMarkdown = ""
            searchResults = []
            workspaceSearchResults = []
            statusText = "Could not open \(url.lastPathComponent)"
        }
    }

    func selectFile(_ url: URL, historyPolicy: NavigationHistoryPolicy = .reset) async {
        if historyPolicy == .reset {
            resetLinkNavigationHistory()
        }
        hoveredLinkDestination = nil
        flushAutosaveIfNeeded()
        selectedFileURL = url
        sidebarSelectionID = url.standardizedFileURL.path
        previewState = .loading(url.lastPathComponent)
        selectedFileWatcher.watch(url: url) { [weak self] in
            Task {
                await self?.handleSelectedFileChangedOnDisk()
            }
        }
        persistState()

        await renderFile(url, statusReason: nil)
    }

    func moveSelection(delta: Int, expandedNodeIDs: Set<String>) async {
        guard let workspace else { return }
        let files = visibleMarkdownFiles(in: workspace.root, expandedNodeIDs: expandedNodeIDs)
        guard !files.isEmpty else { return }

        let currentIndex = selectedFileURL.flatMap { selected in
            files.firstIndex { $0.url.standardizedFileURL.path == selected.standardizedFileURL.path }
        } ?? 0

        let nextIndex = min(max(currentIndex + delta, 0), files.count - 1)
        await selectFile(files[nextIndex].url)
    }

    func visibleSidebarRows() -> [VisibleWorkspaceRow] {
        guard let workspace else { return [] }
        return treeNavigator.visibleRows(root: workspace.root, expandedNodeIDs: expandedNodeIDs)
    }

    func selectSidebarNode(_ node: WorkspaceNode) {
        sidebarSelectionID = node.id
    }

    func handleSidebarNodeClick(_ node: WorkspaceNode) {
        let now = Date()
        defer {
            lastSidebarClickID = node.id
            lastSidebarClickAt = now
        }

        guard node.kind == .markdownFile else {
            selectSidebarNode(node)
            return
        }

        if sidebarSelectionID == node.id,
           lastSidebarClickID == node.id,
           let lastSidebarClickAt,
           now.timeIntervalSince(lastSidebarClickAt) >= sidebarRenameDelay {
            beginRenaming(node)
            return
        }

        Task {
            selectSidebarNode(node)
            await selectFile(node.url)
        }
    }

    func beginRenaming(_ node: WorkspaceNode) {
        guard node.kind == .markdownFile else { return }
        statusText = "Renaming \(node.name)"
        presentRenamePanel(for: node)
    }

    private func presentRenamePanel(for node: WorkspaceNode) {
        let input = NSTextField(string: node.url.deletingPathExtension().lastPathComponent)
        input.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        input.lineBreakMode = .byTruncatingMiddle

        let alert = NSAlert()
        alert.messageText = "Rename \(node.name)"
        alert.informativeText = "Enter a new Markdown file name."
        alert.alertStyle = .informational
        alert.accessoryView = input
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = input

        input.selectText(nil)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            statusText = selectedFileURL.map { "\($0.lastPathComponent) selected" } ?? statusText
            return
        }

        Task { @MainActor in
            await rename(node, to: input.stringValue)
        }
    }

    private func rename(_ node: WorkspaceNode, to proposedName: String) async {
        let trimmed = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        flushAutosaveIfNeeded()

        let sanitizedName = trimmed.replacingOccurrences(of: "/", with: "-")
        let typedExtension = URL(fileURLWithPath: sanitizedName).pathExtension.lowercased()
        let fileName = typedExtension == "md" || typedExtension == "markdown"
            ? sanitizedName
            : "\(sanitizedName).\(node.url.pathExtension.isEmpty ? "md" : node.url.pathExtension)"
        let destination = node.url
            .deletingLastPathComponent()
            .appendingPathComponent(fileName)
            .standardizedFileURL

        if destination.path == node.url.standardizedFileURL.path {
            return
        }

        guard !FileManager.default.fileExists(atPath: destination.path) else {
            statusText = "\(destination.lastPathComponent) already exists"
            return
        }

        do {
            try FileManager.default.moveItem(at: node.url, to: destination)
            await refreshWorkspaceFromDisk(preferredSelectedFile: destination)
            await selectFile(destination)
            statusText = "\(destination.lastPathComponent) renamed"
        } catch {
            statusText = "Could not rename \(node.name)"
        }
    }

    func isSidebarNodeSelected(_ node: WorkspaceNode) -> Bool {
        sidebarSelectionID == node.id
    }

    func moveSidebarSelection(delta: Int) {
        let rows = visibleSidebarRows()
        guard !rows.isEmpty else { return }
        let currentID = sidebarSelectionID ?? selectedFileURL?.standardizedFileURL.path
        let currentIndex = currentID.flatMap { id in rows.firstIndex { $0.id == id } } ?? 0
        let nextIndex = min(max(currentIndex + delta, 0), rows.count - 1)
        sidebarSelectionID = rows[nextIndex].id
    }

    func collapseOrMoveSidebarSelection() {
        guard let workspace else { return }
        ensureSidebarSelection()
        guard let selectedID = sidebarSelectionID,
              let row = visibleSidebarRows().first(where: { $0.id == selectedID })
        else { return }

        if row.kind == .folder, expandedNodeIDs.contains(row.id) {
            expandedNodeIDs.remove(row.id)
        } else if let parentID = row.parentID {
            sidebarSelectionID = parentID
        } else if let selectedFileURL {
            sidebarSelectionID = selectedFileURL.standardizedFileURL.path
        } else {
            sidebarSelectionID = workspace.root.id
        }
    }

    func expandOrEnterSidebarSelection() {
        guard let workspace else { return }
        ensureSidebarSelection()
        guard let selectedID = sidebarSelectionID,
              let node = treeNavigator.node(id: selectedID, in: workspace.root),
              node.kind == .folder
        else { return }

        if !expandedNodeIDs.contains(node.id) {
            expandedNodeIDs.insert(node.id)
        } else if let firstChild = node.children.first {
            sidebarSelectionID = firstChild.id
        }
    }

    func toggleSidebarFolderExpansion() {
        guard let workspace else { return }
        ensureSidebarSelection()
        guard let selectedID = sidebarSelectionID,
              let node = treeNavigator.node(id: selectedID, in: workspace.root),
              node.kind == .folder
        else { return }

        if expandedNodeIDs.contains(node.id) {
            expandedNodeIDs.remove(node.id)
        } else {
            expandedNodeIDs.insert(node.id)
        }
    }

    func activateSidebarSelection() async {
        guard let workspace else { return }
        ensureSidebarSelection()
        guard let selectedID = sidebarSelectionID,
              let node = treeNavigator.node(id: selectedID, in: workspace.root),
              node.kind == .markdownFile
        else { return }

        await selectFile(node.url)
    }

    func toggleSearch() {
        isSearchVisible.toggle()
        if !isSearchVisible {
            searchQuery = ""
        }
    }

    func toggleLeftSidebar() {
        isLeftSidebarVisible.toggle()
    }

    func toggleOutline() {
        isOutlineVisible.toggle()
    }

    func resizeLeftSidebar(by delta: Double) {
        leftSidebarWidth = PaneLayout.clampedLeftWidth(leftSidebarWidth + delta)
    }

    func resizeRightOutline(by delta: Double) {
        rightOutlineWidth = PaneLayout.clampedRightWidth(rightOutlineWidth - delta)
    }

    func showShortcutHelp() {
        isShortcutHelpPresented = true
    }

    func makeDefaultMarkdownReader() {
        switch DefaultMarkdownReaderRegistration.makeDefaultReader(bundleIdentifier: Bundle.main.bundleIdentifier) {
        case .success:
            statusText = "Markdown is now the default reader for Markdown files"
        case .failure(let error):
            statusText = error.userMessage
        }
    }

    func revealSelectedFileInFinder() {
        guard let selectedFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedFileURL])
    }

    func linkHoverChanged(href: String?, resolvedHref: String?, documentURL: URL) {
        guard let href,
              !href.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            hoveredLinkDestination = nil
            return
        }

        let destination = linkResolver.resolve(
            href: href,
            resolvedHref: resolvedHref,
            documentURL: documentURL
        )
        hoveredLinkDestination = displayString(for: destination)
    }

    func openLink(href: String, resolvedHref: String?, documentURL: URL) async {
        hoveredLinkDestination = nil
        let destination = linkResolver.resolve(
            href: href,
            resolvedHref: resolvedHref,
            documentURL: documentURL
        )

        switch destination {
        case let .externalURL(url):
            NSWorkspace.shared.open(url)
            statusText = "Opened \(url.host(percentEncoded: false) ?? url.absoluteString) in browser"
        case let .markdownFile(fileURL, fragment):
            await openMarkdownLink(fileURL: fileURL, fragment: fragment)
        case let .unsupported(url):
            statusText = unsupportedLinkStatus(for: url)
        }
    }

    func goBackInLinkHistory() async {
        guard let destination = navigationBackStack.popLast() else { return }
        if let currentLocation {
            navigationForwardStack.append(currentLocation)
        }
        await restoreNavigationLocation(destination)
    }

    func goForwardInLinkHistory() async {
        guard let destination = navigationForwardStack.popLast() else { return }
        if let currentLocation {
            navigationBackStack.append(currentLocation)
        }
        await restoreNavigationLocation(destination)
    }

    var canCreateMarkdownFile: Bool {
        workspace?.root.kind == .folder
    }

    var canRenameSelectedFile: Bool {
        selectedRenameNode() != nil
    }

    func beginRenamingSelectedFile() {
        guard let node = selectedRenameNode() else { return }
        beginRenaming(node)
    }

    func createMarkdownFileInFolderView() async {
        guard let workspace,
              workspace.root.kind == .folder
        else { return }

        let targetDirectory = targetDirectoryForNewMarkdownFile(in: workspace)
        let newFileURL = uniqueMarkdownFileURL(in: targetDirectory)

        do {
            try Data().write(to: newFileURL, options: .withoutOverwriting)
            expandedNodeIDs.insert(targetDirectory.standardizedFileURL.path)
            await refreshWorkspaceFromDisk()
            await selectFile(newFileURL)
            statusText = "\(newFileURL.lastPathComponent) created"
        } catch {
            statusText = "Could not create \(newFileURL.lastPathComponent)"
        }
    }

    func saveSelectedFile() {
        autosaveTask?.cancel()
        writeCurrentDocumentToDisk(statusVerb: "saved")
    }

    func editorDocumentChanged(_ markdown: String) {
        guard markdown != currentMarkdown else { return }
        currentMarkdown = markdown
        isDocumentDirty = true
        documentOutline = analyzer.outline(for: markdown)
        updateSearchResults()

        guard let selectedFileURL else { return }
        statusText = "\(selectedFileURL.lastPathComponent) edited"
        scheduleAutosave()
    }

    func jump(to item: DocumentOutlineItem) {
        previewActionToken += 1
        pendingPreviewAction = PreviewAction(token: previewActionToken, kind: .jumpToAnchor(item.id))
    }

    func selectSearchResult(_ result: DocumentSearchResult) {
        previewActionToken += 1
        pendingPreviewAction = PreviewAction(
            token: previewActionToken,
            kind: .findText(query: searchQuery, occurrence: result.occurrence)
        )
    }

    func selectWorkspaceSearchResult(_ result: WorkspaceSearchResult) {
        Task {
            await selectFile(result.fileURL)
            previewActionToken += 1
            pendingPreviewAction = PreviewAction(
                token: previewActionToken,
                kind: .findText(query: searchQuery, occurrence: result.occurrence)
            )
        }
    }

    func refreshSelectedFile(reason: String? = nil) async {
        guard let selectedFileURL else { return }
        await renderFile(selectedFileURL, statusReason: reason)
    }

    private func handleSelectedFileChangedOnDisk() async {
        guard let selectedFileURL else { return }

        if let diskMarkdown = try? String(contentsOf: selectedFileURL, encoding: .utf8),
           diskMarkdown == currentMarkdown {
            return
        }

        guard !isDocumentDirty else {
            statusText = "\(selectedFileURL.lastPathComponent) changed on disk while unsaved"
            return
        }

        await refreshSelectedFile(reason: "updated on disk")
    }

    func refreshWorkspaceFromDisk(preferredSelectedFile: URL? = nil) async {
        guard let lastOpenedURL else { return }
        let selected = selectedFileURL
        let savedExpanded = expandedNodeIDs
        let previousRoot = workspace?.root

        do {
            let refreshed = try treeBuilder.build(from: lastOpenedURL)
            workspace = refreshed
            statusText = status(for: refreshed)
            preserveExpandedNodes(savedExpanded, for: refreshed)
            watchDirectories(in: refreshed)

            if let preferredSelectedFile,
               containsFile(preferredSelectedFile, in: refreshed.root) {
                await selectFile(preferredSelectedFile)
                return
            }

            if let selected,
               let previousRoot,
               let replacement = treeNavigator.replacementMarkdownFile(
                   previousRoot: previousRoot,
                   selectedFileURL: selected,
                   newRoot: refreshed.root
               ) {
                if replacement.url.standardizedFileURL.path == selected.standardizedFileURL.path {
                    selectedFileURL = selected
                    sidebarSelectionID = selected.standardizedFileURL.path
                    persistState()
                    return
                }

                await selectFile(replacement.url)
                return
            }

            selectedFileWatcher.stop()
            selectedFileURL = nil
            sidebarSelectionID = refreshed.root.id
            documentOutline = []
            currentMarkdown = ""
            searchResults = []
            workspaceSearchResults = []

            if let first = firstMarkdownFile(in: refreshed.root) {
                await selectFile(first.url)
            } else {
                previewState = .empty
                statusText = selected == nil ? "\(refreshed.root.name) has no Markdown files" : "Selected file was removed"
                persistState()
            }
        } catch {
            workspace = nil
            selectedFileURL = nil
            sidebarSelectionID = nil
            previewState = .failure(error.localizedDescription)
            selectedFileWatcher.stop()
            directoryWatcher.stop()
            documentOutline = []
            currentMarkdown = ""
            searchResults = []
            workspaceSearchResults = []
            statusText = "Could not refresh workspace"
        }
    }

    private var currentLocation: NavigationLocation? {
        guard let lastOpenedURL else { return nil }
        return NavigationLocation(
            openedURL: lastOpenedURL.standardizedFileURL,
            selectedFileURL: selectedFileURL?.standardizedFileURL
        )
    }

    private func openMarkdownLink(fileURL: URL, fragment: String?) async {
        let standardizedFileURL = fileURL.standardizedFileURL

        if selectedFileURL?.standardizedFileURL.path == standardizedFileURL.path {
            jumpToLinkFragment(fragment)
            statusText = fragment == nil
                ? "Already viewing \(standardizedFileURL.lastPathComponent)"
                : "Jumped to \(standardizedFileURL.lastPathComponent)"
            return
        }

        if let currentLocation {
            navigationBackStack.append(currentLocation)
            navigationForwardStack.removeAll()
        }

        if let workspace,
           containsFile(standardizedFileURL, in: workspace.root) {
            revealFileInSidebar(standardizedFileURL)
            await selectFile(standardizedFileURL, historyPolicy: .preserve)
        } else {
            await open(url: standardizedFileURL, preferredSelectedFile: standardizedFileURL, historyPolicy: .preserve)
        }

        jumpToLinkFragment(fragment)
        statusText = "\(standardizedFileURL.lastPathComponent) opened from link"
    }

    private func restoreNavigationLocation(_ location: NavigationLocation) async {
        if let workspace,
           lastOpenedURL?.standardizedFileURL.path == location.openedURL.standardizedFileURL.path,
           let selectedFileURL = location.selectedFileURL,
           containsFile(selectedFileURL, in: workspace.root) {
            revealFileInSidebar(selectedFileURL)
            await selectFile(selectedFileURL, historyPolicy: .preserve)
            statusText = "\(selectedFileURL.lastPathComponent) restored"
            return
        }

        await open(url: location.openedURL, preferredSelectedFile: location.selectedFileURL, historyPolicy: .preserve)
        if let selectedFileURL = location.selectedFileURL {
            revealFileInSidebar(selectedFileURL)
            statusText = "\(selectedFileURL.lastPathComponent) restored"
        }
    }

    private func jumpToLinkFragment(_ fragment: String?) {
        guard let fragment,
              !fragment.isEmpty
        else { return }
        previewActionToken += 1
        pendingPreviewAction = PreviewAction(token: previewActionToken, kind: .jumpToAnchor(fragment))
    }

    private func resetLinkNavigationHistory() {
        navigationBackStack.removeAll()
        navigationForwardStack.removeAll()
        hoveredLinkDestination = nil
    }

    private func updateNavigationAvailability() {
        canNavigateBack = !navigationBackStack.isEmpty
        canNavigateForward = !navigationForwardStack.isEmpty
    }

    private func revealFileInSidebar(_ fileURL: URL) {
        guard let workspace,
              let ancestorIDs = ancestorFolderIDs(containing: fileURL, in: workspace.root)
        else { return }
        expandedNodeIDs.formUnion(ancestorIDs)
        sidebarSelectionID = fileURL.standardizedFileURL.path
    }

    private func ancestorFolderIDs(containing fileURL: URL, in node: WorkspaceNode, ancestors: [String] = []) -> [String]? {
        if node.kind == .markdownFile {
            return node.url.standardizedFileURL.path == fileURL.standardizedFileURL.path ? ancestors : nil
        }

        for child in node.children {
            if let found = ancestorFolderIDs(containing: fileURL, in: child, ancestors: ancestors + [node.id]) {
                return found
            }
        }

        return nil
    }

    private func displayString(for destination: MarkdownLinkDestination) -> String {
        switch destination {
        case let .externalURL(url):
            return url.absoluteString
        case let .markdownFile(fileURL, fragment):
            return displayPath(fileURL, fragment: fragment)
        case let .unsupported(url):
            guard let url else { return "Unsupported link" }
            if url.isFileURL {
                return displayPath(url, fragment: url.fragment)
            }
            return url.absoluteString
        }
    }

    private func displayPath(_ fileURL: URL, fragment: String?) -> String {
        let path: String
        if let workspace,
           workspace.root.kind == .folder {
            path = Self.relativeDisplayPath(for: fileURL, rootURL: workspace.rootURL)
        } else {
            path = fileURL.standardizedFileURL.path
        }

        guard let fragment,
              !fragment.isEmpty
        else { return path }
        return "\(path)#\(fragment)"
    }

    private func unsupportedLinkStatus(for url: URL?) -> String {
        guard let url else { return "Could not open link" }
        if url.isFileURL {
            return "\(url.lastPathComponent) is not a Markdown file"
        }
        return "\(url.scheme ?? "Link") links are not supported"
    }

    private func prepareAppStateIfNeeded() {
        guard !hasPreparedAppState else { return }
        hasPreparedAppState = true

        restoredState = settings.load()
        recentDocuments = restoredState.recentDocuments.filter { FileManager.default.fileExists(atPath: $0.path) }
        isApplyingRestoredState = true
        leftSidebarWidth = restoredState.leftSidebarWidth
        rightOutlineWidth = restoredState.rightOutlineWidth
        isLeftSidebarVisible = restoredState.isLeftSidebarVisible
        isOutlineVisible = restoredState.isOutlineVisible
        isApplyingRestoredState = false
        installShortcutMonitor()
        startResourceSampling()
    }

    private func preferredExternalOpenURL(from urls: [URL]) -> URL? {
        let standardizedURLs = urls.map(\.standardizedFileURL)
        return standardizedURLs.first(where: isSupportedExternalOpenURL) ?? standardizedURLs.first
    }

    private func isSupportedExternalOpenURL(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue || WorkspaceTreeBuilder.isMarkdownFile(url)
    }

    private func renderFile(_ url: URL, statusReason: String?) async {
        autosaveTask?.cancel()
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let start = DispatchTime.now().uptimeNanoseconds
            let rendered = renderer.render(markdown: markdown, sourceURL: url)
            let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
            let title = rendered.title ?? url.deletingPathExtension().lastPathComponent
            currentMarkdown = markdown
            isDocumentDirty = false
            documentOutline = rendered.outline
            updateSearchResults()
            previewState = .rendered(fileURL: url, title: title, markdown: markdown, html: rendered.html)
            let suffix = statusReason.map { " (\($0))" } ?? ""
            statusText = "\(url.lastPathComponent) rendered in \(String(format: "%.1f", elapsedMs)) ms\(suffix)"
            scheduleResourceSample()
        } catch {
            previewState = .failure(error.localizedDescription)
            selectedFileWatcher.stop()
            documentOutline = []
            currentMarkdown = ""
            isDocumentDirty = false
            searchResults = []
            workspaceSearchResults = []
            statusText = "Could not render \(url.lastPathComponent)"
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        guard selectedFileURL != nil else { return }
        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: autosaveDelay)
            guard !Task.isCancelled else { return }
            writeCurrentDocumentToDisk(statusVerb: "autosaved")
        }
    }

    private func flushAutosaveIfNeeded() {
        autosaveTask?.cancel()
        guard isDocumentDirty else { return }
        writeCurrentDocumentToDisk(statusVerb: "autosaved")
    }

    private func writeCurrentDocumentToDisk(statusVerb: String) {
        guard let selectedFileURL else { return }
        do {
            try currentMarkdown.write(to: selectedFileURL, atomically: true, encoding: .utf8)
            isDocumentDirty = false
            statusText = "\(selectedFileURL.lastPathComponent) \(statusVerb)"
            scheduleResourceSample()
        } catch {
            statusText = "Could not save \(selectedFileURL.lastPathComponent)"
        }
    }

    private func updateSearchResults() {
        searchResults = analyzer.search(markdown: currentMarkdown, query: searchQuery)
        scheduleWorkspaceSearch()
    }

    private func status(for workspace: Workspace) -> String {
        if workspace.root.kind == .markdownFile {
            return "Single Markdown file"
        }
        let folderWord = workspace.folderCount == 1 ? "folder" : "folders"
        let fileWord = workspace.markdownFileCount == 1 ? "Markdown file" : "Markdown files"
        if workspace.issues.isEmpty {
            return "\(workspace.folderCount) \(folderWord), \(workspace.markdownFileCount) \(fileWord)"
        }
        return "\(workspace.folderCount) \(folderWord), \(workspace.markdownFileCount) \(fileWord), \(workspace.issues.count) skipped"
    }

    private func firstMarkdownFile(in node: WorkspaceNode) -> WorkspaceNode? {
        if node.kind == .markdownFile {
            return node
        }
        for child in node.children {
            if let found = firstMarkdownFile(in: child) {
                return found
            }
        }
        return nil
    }

    private func containsFile(_ url: URL, in node: WorkspaceNode) -> Bool {
        if node.kind == .markdownFile {
            return node.url.standardizedFileURL.path == url.standardizedFileURL.path
        }
        return node.children.contains { containsFile(url, in: $0) }
    }

    private func visibleMarkdownFiles(in node: WorkspaceNode, expandedNodeIDs: Set<String>) -> [WorkspaceNode] {
        if node.kind == .markdownFile {
            return [node]
        }
        guard node == workspace?.root || expandedNodeIDs.contains(node.id) else {
            return []
        }
        return node.children.flatMap { visibleMarkdownFiles(in: $0, expandedNodeIDs: expandedNodeIDs) }
    }

    private func ensureSidebarSelection() {
        guard sidebarSelectionID == nil else { return }
        if let selectedFileURL {
            sidebarSelectionID = selectedFileURL.standardizedFileURL.path
        } else if let workspace {
            sidebarSelectionID = workspace.root.id
        }
    }

    private func allMarkdownFiles(in node: WorkspaceNode) -> [WorkspaceNode] {
        if node.kind == .markdownFile {
            return [node]
        }
        return node.children.flatMap { allMarkdownFiles(in: $0) }
    }

    private func targetDirectoryForNewMarkdownFile(in workspace: Workspace) -> URL {
        if let selectedID = sidebarSelectionID,
           let selectedNode = treeNavigator.node(id: selectedID, in: workspace.root) {
            if selectedNode.kind == .folder {
                return selectedNode.url.standardizedFileURL
            }
            return selectedNode.url.deletingLastPathComponent().standardizedFileURL
        }

        if let selectedFileURL {
            return selectedFileURL.deletingLastPathComponent().standardizedFileURL
        }

        return workspace.rootURL.standardizedFileURL
    }

    private func uniqueMarkdownFileURL(in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseName = "Untitled"
        let fileExtension = "md"
        var candidate = directory.appendingPathComponent("\(baseName).\(fileExtension)")
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) \(suffix).\(fileExtension)")
            suffix += 1
        }

        return candidate.standardizedFileURL
    }

    private func selectedRenameNode() -> WorkspaceNode? {
        guard let workspace else { return nil }
        let preferredID = sidebarSelectionID ?? selectedFileURL?.standardizedFileURL.path
        guard let preferredID,
              let node = treeNavigator.node(id: preferredID, in: workspace.root),
              node.kind == .markdownFile
        else { return nil }
        return node
    }

    private func scheduleWorkspaceSearch() {
        workspaceSearchTask?.cancel()
        workspaceSearchResults = []
        isWorkspaceSearchRunning = false

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty,
              let workspace,
              workspace.root.kind == .folder
        else {
            return
        }

        let rootURL = workspace.rootURL.standardizedFileURL
        let files = allMarkdownFiles(in: workspace.root)
        guard !files.isEmpty else { return }

        isWorkspaceSearchRunning = true
        let analyzer = self.analyzer
        workspaceSearchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }

            let results = await Task.detached(priority: .userInitiated) {
                var collected: [WorkspaceSearchResult] = []
                for file in files {
                    guard !Task.isCancelled else { return collected }
                    guard let markdown = try? String(contentsOf: file.url, encoding: .utf8) else { continue }
                    let relativePath = Self.relativeDisplayPath(for: file.url, rootURL: rootURL)
                    collected.append(contentsOf: analyzer.searchWorkspaceFile(
                        fileURL: file.url,
                        relativePath: relativePath,
                        markdown: markdown,
                        query: query,
                        limit: 6
                    ))
                    if collected.count >= 120 {
                        return Array(collected.prefix(120))
                    }
                }
                return collected
            }.value

            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self?.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else { return }
                self?.workspaceSearchResults = results
                self?.isWorkspaceSearchRunning = false
            }
        }
    }

    private nonisolated static func relativeDisplayPath(for fileURL: URL, rootURL: URL) -> String {
        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return fileURL.lastPathComponent
        }
        let startIndex = filePath.index(filePath.startIndex, offsetBy: rootPath.count)
        let relative = filePath[startIndex...].trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return relative.isEmpty ? fileURL.lastPathComponent : relative
    }

    private func rememberRecent(url: URL, workspace: Workspace) {
        let standardized = url.standardizedFileURL
        let kind: RecentDocument.Kind = workspace.root.kind == .folder ? .folder : .file
        let recent = RecentDocument(path: standardized.path, kind: kind, lastOpenedAt: Date())
        recentDocuments.removeAll { $0.path == recent.path }
        recentDocuments.insert(recent, at: 0)
        recentDocuments = Array(recentDocuments.prefix(8))
        persistState()
    }

    private func restoreExpandedNodesIfPossible(for workspace: Workspace) {
        preserveExpandedNodes(Set(restoredState.expandedNodeIDs), for: workspace)
    }

    private func preserveExpandedNodes(_ saved: Set<String>, for workspace: Workspace) {
        let available = allFolderIDs(in: workspace.root)
        let restored = saved.intersection(available)
        if restored.isEmpty {
            expandedNodeIDs = Set(defaultExpandedFolderIDs(from: workspace.root, depth: 0))
        } else {
            expandedNodeIDs = restored
        }
    }

    private func allFolderIDs(in node: WorkspaceNode) -> Set<String> {
        var ids = node.kind == .folder ? Set([node.id]) : Set<String>()
        for child in node.children {
            ids.formUnion(allFolderIDs(in: child))
        }
        return ids
    }

    private func defaultExpandedFolderIDs(from node: WorkspaceNode, depth: Int) -> [String] {
        guard node.kind == .folder, depth < 2 else { return [] }
        return [node.id] + node.children.flatMap { defaultExpandedFolderIDs(from: $0, depth: depth + 1) }
    }

    private func watchDirectories(in workspace: Workspace) {
        guard workspace.root.kind == .folder else {
            directoryWatcher.stop()
            return
        }
        directoryWatcher.watch(urls: folderURLs(in: workspace.root)) { [weak self] in
            Task { await self?.refreshWorkspaceFromDisk() }
        }
    }

    private func folderURLs(in node: WorkspaceNode) -> [URL] {
        guard node.kind == .folder else { return [] }
        return [node.url] + node.children.flatMap { folderURLs(in: $0) }
    }

    private func installShortcutMonitor() {
        shortcutMonitor.install(
            onBack: { [weak self] in
                guard let self else { return }
                Task { await self.goBackInLinkHistory() }
            },
            onForward: { [weak self] in
                guard let self else { return }
                Task { await self.goForwardInLinkHistory() }
            },
            onPreviousFile: { [weak self] in
                guard let self else { return }
                Task { await self.moveSelection(delta: -1, expandedNodeIDs: self.expandedNodeIDs) }
            },
            onNextFile: { [weak self] in
                guard let self else { return }
                Task { await self.moveSelection(delta: 1, expandedNodeIDs: self.expandedNodeIDs) }
            },
            onToggleLeftPane: { [weak self] in
                self?.toggleLeftSidebar()
            },
            onToggleRightPane: { [weak self] in
                self?.toggleOutline()
            }
        )
    }

    private func startResourceSampling() {
        guard resourceTimer == nil else { return }
        resourceTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleResourcesIfVisible()
            }
        }
    }

    private func sampleResourcesIfVisible() {
        guard NSApplication.shared.isActive,
              NSApplication.shared.windows.contains(where: { $0.isVisible && !$0.isMiniaturized })
        else {
            return
        }
        resourceText = resourceSampler.sample().displayText
    }

    private func scheduleResourceSample() {
        resourceSampleTask?.cancel()
        resourceSampleTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1_200))
            guard !Task.isCancelled else { return }
            sampleResourcesIfVisible()
        }
    }

    private func persistState() {
        let state = RestoredAppState(
            lastOpenedPath: lastOpenedURL?.path,
            selectedFilePath: selectedFileURL?.standardizedFileURL.path,
            expandedNodeIDs: Array(expandedNodeIDs),
            recentDocuments: recentDocuments,
            leftSidebarWidth: leftSidebarWidth,
            rightOutlineWidth: rightOutlineWidth,
            isLeftSidebarVisible: isLeftSidebarVisible,
            isOutlineVisible: isOutlineVisible
        )
        settings.save(state)
    }
}
