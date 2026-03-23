//
//  ContentView.swift
//  SearchGithubRepo
//

import SwiftUI

struct ContentView: View {
    @StateObject private var searchContainer = SearchContainer()

    var body: some View {
        SearchView(container: searchContainer)
    }
}

#Preview {
    ContentView()
}
