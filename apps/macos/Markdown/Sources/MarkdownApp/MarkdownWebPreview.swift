import MarkdownAppSupport
import SwiftUI
import WebKit

struct MarkdownWebPreview: NSViewRepresentable {
    let html: String
    let baseURL: URL
    let action: PreviewAction?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let key = "\(baseURL.path)#\(html.hashValue)"
        if context.coordinator.lastLoadedKey != key {
            context.coordinator.lastLoadedKey = key
            context.coordinator.isLoaded = false
            context.coordinator.lastActionToken = nil
            context.coordinator.pendingAction = action
            webView.loadHTMLString(html, baseURL: baseURL)
            return
        }

        guard let action, context.coordinator.lastActionToken != action.token else { return }
        context.coordinator.perform(action, in: webView)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadedKey: String?
        var lastActionToken: Int?
        var pendingAction: PreviewAction?
        var isLoaded = false

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
