import AppKit
import SwiftUI

@main
struct MarkdownApplication: App {
    @StateObject private var model = AppModel()

    init() {
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.light)
                .task {
                    await model.openLaunchArgumentIfPresent()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
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
