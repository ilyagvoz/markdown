import AppKit
import MarkdownAppSupport
import SwiftUI
import WebKit

struct MarkdownEditorView: NSViewRepresentable {
    let markdown: String
    let title: String
    let documentURL: URL
    let baseURL: URL
    let action: PreviewAction?
    let onChange: (String) -> Void
    let onSave: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange, onSave: onSave)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.add(context.coordinator, name: "editor")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onChange = onChange
        context.coordinator.onSave = onSave

        let documentID = documentURL.standardizedFileURL.path
        let key = "\(documentID)#\(markdown.hashValue)"
        let isNewDocument = context.coordinator.lastDocumentID != documentID
        if context.coordinator.lastLoadedKey != key, isNewDocument || !context.coordinator.isDirty {
            context.coordinator.lastDocumentID = documentID
            context.coordinator.lastLoadedKey = key
            context.coordinator.isLoaded = false
            context.coordinator.isDirty = false
            context.coordinator.lastActionToken = nil
            context.coordinator.pendingAction = action
            let html = MarkdownEditorHTML.document(markdown: markdown, title: title)
            webView.loadHTMLString(html, baseURL: baseURL)
            return
        }

        guard let action, context.coordinator.lastActionToken != action.token else { return }
        context.coordinator.perform(action, in: webView)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var lastLoadedKey: String?
        var lastDocumentID: String?
        var lastActionToken: Int?
        var pendingAction: PreviewAction?
        var isLoaded = false
        var isDirty = false
        var onChange: (String) -> Void
        var onSave: () -> Void

        init(onChange: @escaping (String) -> Void, onSave: @escaping () -> Void) {
            self.onChange = onChange
            self.onSave = onSave
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "editor",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String
            else { return }

            switch type {
            case "documentChanged":
                guard let markdown = body["markdown"] as? String else { return }
                isDirty = true
                onChange(markdown)
            case "saveRequested":
                onSave()
                isDirty = false
            case "copyRequested":
                guard let markdown = body["copyMarkdown"] as? String else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(markdown, forType: .string)
            default:
                break
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            guard let pendingAction else { return }
            execute(pendingAction, in: webView)
            self.pendingAction = nil
        }

        func perform(_ action: PreviewAction, in webView: WKWebView) {
            guard isLoaded else {
                pendingAction = action
                return
            }
            execute(action, in: webView)
        }

        private func execute(_ action: PreviewAction, in webView: WKWebView) {
            lastActionToken = action.token

            let script: String
            switch action.kind {
            case let .jumpToAnchor(anchorID):
                script = PreviewJavaScript.jumpToAnchorScript(anchorID: anchorID)
            case let .findText(query, occurrence):
                script = PreviewJavaScript.findTextScript(query: query, occurrence: occurrence)
            }
            webView.evaluateJavaScript(script) { _, _ in }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url
            else {
                decisionHandler(.allow)
                return
            }

            if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
