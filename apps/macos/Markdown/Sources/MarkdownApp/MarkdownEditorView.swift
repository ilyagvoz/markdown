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
    let onLinkHover: (String?, String?) -> Void
    let onOpenLink: (String, String?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onChange: onChange,
            onSave: onSave,
            onLinkHover: onLinkHover,
            onOpenLink: onOpenLink
        )
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
        webView.unregisterDraggedTypes()
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.onChange = onChange
        context.coordinator.onSave = onSave
        context.coordinator.onLinkHover = onLinkHover
        context.coordinator.onOpenLink = onOpenLink

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
            let html = MarkdownEditorHTML.document(markdown: markdown, title: title, baseURL: baseURL)
            context.coordinator.load(html: html, baseURL: baseURL, in: webView)
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
        var temporaryHTMLURL: URL?
        var onChange: (String) -> Void
        var onSave: () -> Void
        var onLinkHover: (String?, String?) -> Void
        var onOpenLink: (String, String?) -> Void

        init(
            onChange: @escaping (String) -> Void,
            onSave: @escaping () -> Void,
            onLinkHover: @escaping (String?, String?) -> Void,
            onOpenLink: @escaping (String, String?) -> Void
        ) {
            self.onChange = onChange
            self.onSave = onSave
            self.onLinkHover = onLinkHover
            self.onOpenLink = onOpenLink
        }

        func load(html: String, baseURL: URL, in webView: WKWebView) {
            do {
                let htmlURL = try writeTemporaryHTML(html)
                let readAccessURL = commonReadAccessURL(for: htmlURL, baseURL: baseURL)
                webView.loadFileURL(htmlURL, allowingReadAccessTo: readAccessURL)
            } catch {
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        }

        private func writeTemporaryHTML(_ html: String) throws -> URL {
            removeTemporaryHTML()

            let directory = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Caches/com.gvozdenko.markdown/MarkdownEditorWebView", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let htmlURL = directory.appendingPathComponent("\(UUID().uuidString).html")
            try html.write(to: htmlURL, atomically: true, encoding: .utf8)
            temporaryHTMLURL = htmlURL
            return htmlURL
        }

        private func commonReadAccessURL(for htmlURL: URL, baseURL: URL) -> URL {
            let htmlComponents = htmlURL.deletingLastPathComponent().standardizedFileURL.pathComponents
            let baseComponents = baseURL.standardizedFileURL.pathComponents
            var commonComponents: [String] = []

            for (htmlComponent, baseComponent) in zip(htmlComponents, baseComponents) {
                guard htmlComponent == baseComponent else { break }
                commonComponents.append(htmlComponent)
            }

            guard !commonComponents.isEmpty else {
                return URL(fileURLWithPath: "/", isDirectory: true)
            }

            let path = NSString.path(withComponents: commonComponents)
            return URL(fileURLWithPath: path, isDirectory: true)
        }

        private func removeTemporaryHTML() {
            guard let temporaryHTMLURL else { return }
            try? FileManager.default.removeItem(at: temporaryHTMLURL)
            self.temporaryHTMLURL = nil
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
            case "linkHovered":
                onLinkHover(body["href"] as? String, body["resolvedHref"] as? String)
            case "linkHoverEnded":
                onLinkHover(nil, nil)
            case "linkActivated":
                guard let href = body["href"] as? String else { return }
                onOpenLink(href, body["resolvedHref"] as? String)
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

            if navigationAction.modifierFlags.contains(.command) || navigationAction.modifierFlags.contains(.control) {
                onOpenLink(url.absoluteString, url.absoluteString)
            }
            decisionHandler(.cancel)
        }
    }
}
