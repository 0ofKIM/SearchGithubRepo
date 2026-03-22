//
//  ContentView.swift
//  SearchGithubRepo
//
//  Created by 0ofKim on 3/22/26.
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
