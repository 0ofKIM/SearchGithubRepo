//
//  RecentSearchSectionView.swift
//  SearchGithubRepo
//

import SwiftUI

struct RecentSearchSectionView: View {
    let recentSearches: [RecentSearchItem]
    let recentSearchesDisplayed: [RecentSearchItem]
    let onSelectRecentSearch: (RecentSearchItem) -> Void
    let onRemoveRecentSearch: (UUID) -> Void
    let onClearAllRecentSearches: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("최근 검색")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if recentSearches.isEmpty {
                Text("최근 검색 내역이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                Divider()
                    .padding(.top, 8)

                Spacer(minLength: 0)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(recentSearchesDisplayed) { recentSearchItem in
                            HStack {
                                Button {
                                    onSelectRecentSearch(recentSearchItem)
                                } label: {
                                    Text(recentSearchItem.query)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    onRemoveRecentSearch(recentSearchItem.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .padding(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 5)
                        }

                        if !recentSearches.isEmpty {
                            Button("전체삭제") {
                                onClearAllRecentSearches()
                            }
                            .font(.subheadline)
                            .foregroundStyle(Color.pink)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }

                        Divider()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
