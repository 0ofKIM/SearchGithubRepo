//
//  RepositoryWebView.swift
//  SearchGithubRepo
//

import SwiftUI
import WebKit

struct RepositoryWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            webView.load(URLRequest(url: url))
        }
    }

    final class Coordinator {
        var lastLoadedURL: URL?
    }
}
