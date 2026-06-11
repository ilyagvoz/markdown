import AppKit
import MarkdownCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            if model.isLeftSidebarVisible {
                SidebarView()
                    .environmentObject(model)
                    .frame(width: CGFloat(model.leftSidebarWidth))
                    .frame(maxHeight: .infinity)

                PaneDivider { delta in
                    model.resizeLeftSidebar(by: delta)
                }
            }

            PreviewPane()
                .environmentObject(model)
                .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)

            if model.isOutlineVisible {
                PaneDivider { delta in
                    model.resizeRightOutline(by: delta)
                }

                OutlinePanel()
                    .environmentObject(model)
                    .frame(width: CGFloat(model.rightOutlineWidth))
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(minWidth: 980, minHeight: 660)
        .tint(.teal)
        .background(AppColors.previewBackground)
        .sheet(isPresented: $model.isShortcutHelpPresented) {
            ShortcutHelpView()
        }
    }
}

struct PaneDivider: View {
    let onDrag: (Double) -> Void
    @State private var lastTranslation = 0.0

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 9)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let delta = value.translation.width - lastTranslation
                        lastTranslation = value.translation.width
                        onDrag(delta)
                    }
                    .onEnded { _ in
                        lastTranslation = 0
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .help("Drag to resize pane")
            .accessibilityLabel("Resize pane")
    }
}

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var isSidebarFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader

            Divider()

            if let workspace = model.workspace {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        TreeNodeView(node: workspace.root, depth: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                }
                .background(AppColors.sidebarBackground)
                .focusable()
                .focusEffectDisabled()
                .focused($isSidebarFocused)
                .onTapGesture {
                    isSidebarFocused = true
                }
                .onMoveCommand { direction in
                    Task {
                        switch direction {
                        case .up:
                            model.moveSidebarSelection(delta: -1)
                        case .down:
                            model.moveSidebarSelection(delta: 1)
                        case .left:
                            model.collapseOrMoveSidebarSelection()
                        case .right:
                            model.expandOrEnterSidebarSelection()
                        default:
                            break
                        }
                    }
                }
                .onKeyPress(.return) {
                    Task { await model.activateSidebarSelection() }
                    return .handled
                }
                .onKeyPress(.space) {
                    model.toggleSidebarFolderExpansion()
                    return .handled
                }
                .onAppear {
                    isSidebarFocused = true
                }
            } else {
                EmptySidebarView()
                    .environmentObject(model)
            }

            Divider()

            StatusBar()
                .environmentObject(model)
        }
        .background(AppColors.sidebarBackground)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.teal)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Markdown")
                        .font(.headline)
                    Text("Preview reader")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                Button {
                    model.presentOpenPanel()
                } label: {
                    Label("Open", systemImage: "folder")
                }
                .help("Open a Markdown file or folder")

                Button {
                    model.toggleSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .help("Search current document")
                .accessibilityLabel("Search current document or workspace")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }
}

struct StatusBar: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(.teal)
            Text(status)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var status: String {
        guard !model.resourceText.isEmpty else { return model.statusText }
        return "\(model.statusText) · \(model.resourceText)"
    }
}

struct EmptySidebarView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Open a file or folder")
                .font(.headline)
            Text("Markdown files appear here in a collapsible tree.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !model.recentDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.top, 8)

                    ForEach(model.recentDocuments) { recent in
                        Button {
                            Task { await model.openRecent(recent) }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: recent.kind == .folder ? "folder" : "doc.text")
                                    .foregroundStyle(.teal)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(recent.name)
                                        .lineLimit(1)
                                    Text(recent.path)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer()
        }
        .padding(26)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TreeNodeView: View {
    @EnvironmentObject private var model: AppModel

    let node: WorkspaceNode
    let depth: Int

    var body: some View {
        if node.kind == .folder {
            DisclosureGroup(isExpanded: expandedBinding) {
                ForEach(node.children) { child in
                    TreeNodeView(node: child, depth: depth + 1)
                }
            } label: {
                rowLabel(icon: "folder", title: node.name, isSelected: model.isSidebarNodeSelected(node))
                    .onTapGesture {
                        model.selectSidebarNode(node)
                    }
            }
            .disclosureGroupStyle(.automatic)
            .padding(.leading, CGFloat(depth) * 12)
            .accessibilityLabel("\(node.name), \(expandedBinding.wrappedValue ? "expanded" : "collapsed") folder")
        } else {
            Button {
                Task {
                    model.selectSidebarNode(node)
                    await model.selectFile(node.url)
                }
            } label: {
                rowLabel(
                    icon: "doc.text",
                    title: node.name,
                    isSelected: model.isSidebarNodeSelected(node)
                )
            }
            .buttonStyle(.plain)
            .padding(.leading, CGFloat(depth) * 12 + 20)
            .accessibilityLabel("\(node.name), Markdown file")
        }
    }

    private var expandedBinding: Binding<Bool> {
        Binding(
            get: { model.expandedNodeIDs.contains(node.id) },
            set: { isExpanded in
                if isExpanded {
                    model.expandedNodeIDs.insert(node.id)
                } else {
                    model.expandedNodeIDs.remove(node.id)
                }
            }
        )
    }

    private func rowLabel(icon: String, title: String, isSelected: Bool) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 13.5, weight: isSelected ? .semibold : .regular))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? AppColors.selection : Color.clear)
        }
        .contentShape(Rectangle())
    }
}

struct PreviewPane: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            if model.isSearchVisible {
                SearchPanel()
                    .environmentObject(model)
                Divider()
            }
            Divider()
            previewBody
        }
        .background(AppColors.previewBackground)
    }

    private var previewHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.teal)
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Button {
                model.toggleSearch()
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help("Search")
            .accessibilityLabel("Search current document or workspace")

            Button {
                model.toggleOutline()
            } label: {
                Image(systemName: model.isOutlineVisible ? "sidebar.right" : "sidebar.right")
            }
            .buttonStyle(.borderless)
            .help("Toggle document outline")
            .accessibilityLabel("Toggle document outline")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }

    @ViewBuilder
    private var previewBody: some View {
        switch model.previewState {
        case .empty:
            EmptyPreviewView()
        case let .loading(name):
            VStack(spacing: 12) {
                ProgressView()
                Text("Rendering \(name)")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .rendered(fileURL, _, html):
            MarkdownWebPreview(
                html: html,
                baseURL: fileURL.deletingLastPathComponent(),
                action: model.pendingPreviewAction
            )
        case let .failure(message):
            ContentUnavailableView(
                "Could not render Markdown",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    private var title: String {
        switch model.previewState {
        case let .rendered(_, title, _):
            return title
        case .empty:
            return "No document selected"
        case let .loading(name):
            return name
        case .failure:
            return "Preview failed"
        }
    }

    private var subtitle: String {
        if let selected = model.selectedFileURL {
            return selected.path
        }
        return "Open a Markdown file or folder to begin"
    }
}

struct SearchPanel: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search current document or workspace", text: $model.searchQuery)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                if !model.searchQuery.isEmpty {
                    Button {
                        model.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if !model.searchQuery.isEmpty {
                currentDocumentResults
                workspaceResults
            }
        }
        .background(AppColors.previewBackground)
        .onAppear {
            isFocused = true
        }
    }

    @ViewBuilder
    private var currentDocumentResults: some View {
        if model.searchResults.isEmpty {
            Text("No matches in current document")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current Document")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.searchResults) { result in
                            Button {
                                model.selectSearchResult(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.headingContext ?? "Line \(result.lineNumber)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text(result.snippet)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .frame(width: 220, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppColors.sidebarBackground)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    @ViewBuilder
    private var workspaceResults: some View {
        if model.isWorkspaceSearchRunning {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Searching workspace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        } else if !model.workspaceSearchResults.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Workspace")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(model.workspaceSearchResults) { result in
                            Button {
                                model.selectWorkspaceSearchResult(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.relativePath)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Text(result.headingContext ?? "Line \(result.lineNumber)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                    Text(result.snippet)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .frame(width: 240, alignment: .leading)
                                .background {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppColors.outlineBackground)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

struct OutlinePanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.indent")
                    .foregroundStyle(.teal)
                Text("Outline")
                    .font(.headline)
                Spacer()
                Button {
                    model.toggleOutline()
                } label: {
                    Image(systemName: "sidebar.right")
                }
                .buttonStyle(.borderless)
                .help("Hide outline")
                .accessibilityLabel("Hide outline")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            if model.documentOutline.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "text.justify.left")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No outline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Headings and document landmarks will appear here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(model.documentOutline) { item in
                            Button {
                                model.jump(to: item)
                            } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: icon(for: item.kind))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 15)
                                    Text(item.title)
                                        .font(.system(size: 12.5, weight: item.kind == .heading ? .medium : .regular))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(.primary)
                                .padding(.leading, CGFloat(max(0, item.level - 1)) * 9)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(AppColors.outlineBackground)
    }

    private func icon(for kind: DocumentOutlineKind) -> String {
        switch kind {
        case .heading:
            return "textformat.size"
        case .table:
            return "tablecells"
        case .codeBlock:
            return "chevron.left.forwardslash.chevron.right"
        case .blockQuote:
            return "quote.opening"
        case .image:
            return "photo"
        case .diagram:
            return "point.3.connected.trianglepath.dotted"
        }
    }
}

struct ShortcutHelpView: View {
    private let shortcuts: [(String, String)] = [
        ("Open file or folder", "Cmd O"),
        ("Search current document", "Cmd F"),
        ("Previous Markdown file", "Cmd Up"),
        ("Next Markdown file", "Cmd Down"),
        ("Toggle left sidebar", "Cmd Left Arrow"),
        ("Toggle right outline", "Cmd Right Arrow"),
        ("Reveal selected file in Finder", "Cmd R"),
        ("Show keyboard shortcuts", "Cmd /"),
        ("Move sidebar selection", "Up / Down"),
        ("Expand or collapse folder", "Left / Right"),
        ("Open highlighted file", "Return"),
        ("Toggle folder expansion", "Space")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Keyboard Shortcuts")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 10) {
                ForEach(shortcuts, id: \.0) { action, shortcut in
                    GridRow {
                        Text(action)
                            .foregroundStyle(.primary)
                        Text(shortcut)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(26)
        .frame(width: 460)
        .background(AppColors.previewBackground)
    }
}

struct EmptyPreviewView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "text.page")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
            Text("Ready for Markdown")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            Text("Open a file or folder and the rendered preview will appear here.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum AppColors {
    static let sidebarBackground = Color(nsColor: NSColor(red: 0.965, green: 0.958, blue: 0.94, alpha: 1))
    static let outlineBackground = Color(nsColor: NSColor(red: 0.972, green: 0.966, blue: 0.952, alpha: 1))
    static let previewBackground = Color(nsColor: NSColor(red: 0.985, green: 0.980, blue: 0.965, alpha: 1))
    static let selection = Color(nsColor: NSColor(red: 0.0, green: 0.47, blue: 0.52, alpha: 1))
    static let divider = Color(nsColor: NSColor.separatorColor.withAlphaComponent(0.72))
}
