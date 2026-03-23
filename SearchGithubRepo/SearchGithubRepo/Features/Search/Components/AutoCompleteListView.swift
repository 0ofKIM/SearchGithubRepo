//
//  AutoCompleteListView.swift
//  SearchGithubRepo
//

import SwiftUI

struct AutoCompleteListView: View {
    let items: [RecentSearchItem]
    let formatDateText: (Date) -> String
    let onSelectRecentSearch: (RecentSearchItem) -> Void

    var body: some View {
        List {
            ForEach(items) { recentSearchItem in
                Button {
                    onSelectRecentSearch(recentSearchItem)
                } label: {
                    HStack {
                        Text(recentSearchItem.query)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formatDateText(recentSearchItem.searchedAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
