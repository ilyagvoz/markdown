import AppKit
import SwiftUI

@main
struct MarkdownApplication: App {
    @NSApplicationDelegateAdaptor(MarkdownApplicationDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    init() {
        SmokeWindowPlacement.applyLaunchDefaultsIfPresent()
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        NSApplication.shared.setActivationPolicy(.regular)
        if !SmokeWindowPlacement.isRequested {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    Task { await model.openExternalURLs([url]) }
                }
                .task {
                    appDelegate.model = model
                    if !(await appDelegate.openPendingURLsIfNeeded()) {
                        await model.openLaunchArgumentIfPresent()
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Markdown File") {
                    Task { await model.createMarkdownFileInFolderView() }
                }
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(!model.canCreateMarkdownFile)

                Button("Open...") {
                    model.presentOpenPanel()
                }
                .keyboardShortcut("o", modifiers: [.command])
            }

            CommandGroup(after: .saveItem) {
                Button("Save") {
                    model.saveSelectedFile()
                }
                .keyboardShortcut("s", modifiers: [.command])

                Button("Reveal in Finder") {
                    model.revealSelectedFileInFinder()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Rename Selected File") {
                    model.beginRenamingSelectedFile()
                }
                .disabled(!model.canRenameSelectedFile)
            }

            CommandMenu("Open Recent") {
                if model.recentDocuments.isEmpty {
                    Text("No Recent Documents")
                } else {
                    ForEach(model.recentDocuments) { recent in
                        Button(recent.name) {
                            Task { await model.openRecent(recent) }
                        }
                    }

                    Divider()

                    Button("Clear Recents") {
                        model.clearRecents()
                    }
                }
            }

            CommandMenu("Navigation") {
                Button("Search") {
                    model.toggleSearch()
                }
                .keyboardShortcut("f", modifiers: [.command])

                Divider()

                Button("Previous Markdown File") {
                    Task { await model.moveSelection(delta: -1, expandedNodeIDs: model.expandedNodeIDs) }
                }
                .keyboardShortcut(.upArrow, modifiers: [.command])

                Button("Next Markdown File") {
                    Task { await model.moveSelection(delta: 1, expandedNodeIDs: model.expandedNodeIDs) }
                }
                .keyboardShortcut(.downArrow, modifiers: [.command])

                Divider()

                Button("Toggle Left Sidebar") {
                    model.toggleLeftSidebar()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])

                Button("Toggle Right Outline") {
                    model.toggleOutline()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Button("Keyboard Shortcuts") {
                    model.showShortcutHelp()
                }
                .keyboardShortcut("/", modifiers: [.command])
            }
        }
    }
}

@MainActor
final class MarkdownApplicationDelegate: NSObject, NSApplicationDelegate {
    weak var model: AppModel?
    private var pendingOpenURLs: [URL] = []

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }

        Task { @MainActor in
            await openURLs(urls)
            sender.reply(toOpenOrPrint: .success)
        }
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        Task { @MainActor in
            await openURLs([url])
        }
        return true
    }

    func openPendingURLsIfNeeded() async -> Bool {
        guard model != nil, !pendingOpenURLs.isEmpty else { return false }
        let urls = pendingOpenURLs
        pendingOpenURLs.removeAll()
        await openURLs(urls)
        return true
    }

    private func openURLs(_ urls: [URL]) async {
        if let model {
            await model.openExternalURLs(urls)
        } else {
            pendingOpenURLs.append(contentsOf: urls)
        }
    }
}

enum SmokeWindowPlacement {
    private static let argumentName = "--smoke-window-frame-default"
    private static let knownWindowFrameKeys = [
        "NSWindow Frame SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<MarkdownApp.ContentView, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<MarkdownApp.AppModel>>>, SwiftUI._TaskModifier2>-1-AppWindow-1",
        "NSWindow Frame SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<SwiftUI.ModifiedContent<MarkdownApp.ContentView, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<MarkdownApp.AppModel>>>, SwiftUI._PreferenceWritingModifier<SwiftUI.PreferredColorSchemeKey>>, SwiftUI._TaskModifier2>-1-AppWindow-1",
    ]

    static var isRequested: Bool {
        CommandLine.arguments.contains(argumentName)
    }

    static func applyLaunchDefaultsIfPresent(arguments: [String] = CommandLine.arguments) {
        guard let index = arguments.firstIndex(of: argumentName),
              arguments.indices.contains(index + 1)
        else { return }

        let frame = arguments[index + 1]
        guard isValidWindowFrameDefault(frame) else { return }

        let defaults = UserDefaults.standard
        for key in existingWindowFrameKeys(in: defaults).union(knownWindowFrameKeys) {
            defaults.set(frame, forKey: key)
        }
        defaults.synchronize()
    }

    private static func existingWindowFrameKeys(in defaults: UserDefaults) -> Set<String> {
        Set(defaults.dictionaryRepresentation().keys.filter { key in
            key.hasPrefix("NSWindow Frame ") && key.contains("AppWindow-1")
        })
    }

    private static func isValidWindowFrameDefault(_ value: String) -> Bool {
        let parts = value.split(separator: " ")
        guard parts.count == 8 else { return false }
        return parts.allSatisfy { Double($0) != nil }
    }
}
