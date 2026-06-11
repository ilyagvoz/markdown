import AppKit
import Darwin
import NativeWebViewEditorSpikeSupport
import WebKit

final class NativeWebViewEditorSpikeApp: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var controller: EditorWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = EditorWindowController(smokeMode: CommandLine.arguments.contains("--smoke"))
        self.controller = controller
        window = controller.window
        window?.makeKeyAndOrderFront(nil)
        if !CommandLine.arguments.contains("--smoke") {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = NativeWebViewEditorSpikeApp()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

final class EditorWindowController: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    let window: NSWindow

    private let webView: WKWebView
    private let statusField = NSTextField(labelWithString: "Loading editor...")
    private let sourceView = NSTextView()
    private var latestMarkdown = ""
    private var eventLog: [String] = []
    private let smokeMode: Bool
    private var didRunSmoke = false

    init(smokeMode: Bool = false) {
        self.smokeMode = smokeMode
        let configuration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        configuration.userContentController = controller
        webView = WKWebView(frame: .zero, configuration: configuration)
        window = NSWindow(
            contentRect: NSRect(x: 80, y: 80, width: 1180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Candidate A Native WebView Editor"

        super.init()

        controller.add(self, name: "editor")
        webView.navigationDelegate = self
        buildLayout()
        loadEditor()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "editor",
              let parsed = EditorBridgeMessageParser.parse(message.body)
        else {
            setStatus("Ignored malformed bridge message")
            return
        }

        handle(parsed)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setStatus("WebView loaded")
        guard smokeMode, !didRunSmoke else { return }
        didRunSmoke = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.runSmokeTest()
        }
    }

    private func handle(_ message: EditorBridgeMessage) {
        if let markdown = message.markdown {
            latestMarkdown = markdown
            sourceView.string = markdown
        }

        let status = EditorBridgeMessageParser.statusText(for: message)
        eventLog.append(status)
        setStatus(status)

        if message.type == .saveRequested {
            NSSound(named: "Tink")?.play()
        }
    }

    private func buildLayout() {
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false

        let webContainer = NSView()
        webContainer.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        statusField.translatesAutoresizingMaskIntoConstraints = false
        statusField.font = .systemFont(ofSize: 12)
        statusField.textColor = .secondaryLabelColor
        webContainer.addSubview(webView)
        webContainer.addSubview(statusField)

        NSLayoutConstraint.activate([
            statusField.leadingAnchor.constraint(equalTo: webContainer.leadingAnchor, constant: 14),
            statusField.trailingAnchor.constraint(equalTo: webContainer.trailingAnchor, constant: -14),
            statusField.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor, constant: -10),
            webView.topAnchor.constraint(equalTo: webContainer.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webContainer.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: statusField.topAnchor, constant: -8)
        ])

        let sourceScroll = NSScrollView()
        sourceScroll.hasVerticalScroller = true
        sourceScroll.translatesAutoresizingMaskIntoConstraints = false
        sourceView.isEditable = false
        sourceView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        sourceView.string = "Waiting for editor state..."
        sourceScroll.documentView = sourceView

        splitView.addArrangedSubview(webContainer)
        splitView.addArrangedSubview(sourceScroll)
        window.contentView = splitView

        sourceScroll.widthAnchor.constraint(equalToConstant: 340).isActive = true
    }

    private func loadEditor() {
        guard let url = Bundle.module.url(forResource: "editor", withExtension: "html", subdirectory: "Resources") else {
            setStatus("Missing editor.html resource")
            if smokeMode {
                fputs("SMOKE_FAIL missing editor.html resource\n", stderr)
                exit(1)
            }
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    private func setStatus(_ value: String) {
        statusField.stringValue = value
    }

    private func runSmokeTest() {
        let script = """
        window.nativeEditorSpike.editLine("line-0", "Native Edited");
        window.nativeEditorSpike.editLine("line-3", "A list item keeps its marker after native smoke edit.");
        window.nativeEditorSpike.unlockLine("line-3");
        window.nativeEditorSpike.rawLine("line-3", "> Quote after unlock.");
        [
          window.nativeEditorSpike.serialized(),
          "---TYPE:" + window.nativeEditorSpike.blockType("line-3"),
          "---MARKER:" + window.nativeEditorSpike.marker("line-3"),
          "---UNLOCKED:" + String(window.nativeEditorSpike.isUnlocked("line-3"))
        ].join("\\n");
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error {
                fputs("SMOKE_FAIL \(error.localizedDescription)\n\(error)\n", stderr)
                exit(1)
            }

            guard let markdown = result as? String else {
                fputs("SMOKE_FAIL serialized markdown was not a string\n", stderr)
                exit(1)
            }

            guard markdown.contains("# Native Edited"),
                  markdown.contains("> Quote after unlock."),
                  !markdown.contains("- > Quote after unlock."),
                  markdown.contains("---TYPE:quote"),
                  markdown.contains("---MARKER:>"),
                  markdown.contains("---UNLOCKED:false")
            else {
                fputs("SMOKE_FAIL serialized markdown did not match expected update behavior\n\(markdown)\n", stderr)
                exit(1)
            }

            print("SMOKE_OK native WebView editor preserved style until explicit unlock")
            NSApplication.shared.terminate(nil)
        }
    }
}
