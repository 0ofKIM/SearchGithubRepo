//
//  SearchView.swift
//  SearchGithubRepo
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var container: SearchContainer
    @FocusState private var searchFocused: Bool

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "MM. dd."
        return f
    }()

    private static let countFormatter: NumberFormatter = {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.locale = Locale(identifier: "ko_KR")
        return n
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarView(
                    fieldFocused: $searchFocused,
                    text: Binding(
                        get: { container.state.searchText },
                        set: { container.send(.searchTextChanged($0)) }
                    ),
                    onSubmit: { container.send(.submitSearch) },
                    onClear: { container.send(.tapClearText) },
                    onCancel: { container.send(.tapCancel) }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                content
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(
                container.state.showsLargeNavigationTitle ? .large : .inline
            )
            .onChange(of: searchFocused) { _, newValue in
                container.send(.searchFieldFocused(newValue))
            }
            .onChange(of: container.state.searchFieldFocused) { _, newValue in
                if newValue != searchFocused {
                    searchFocused = newValue
                }
            }
            .onAppear {
                searchFocused = container.state.searchFieldFocused
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let state = container.state

        if state.showsResultsSection {
            resultsContent(state: state)
        } else if state.showsAutocomplete {
            autocompleteList(state: state)
        } else if state.showsRecentSection {
            recentSection(state: state)
        } else {
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func resultsContent(state: SearchState) -> some View {
        Group {
            if state.isLoadingResults {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 24)
            } else if let message = state.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 24)
            } else {
                List {
                    Section {
                        ForEach(state.repositories) { repository in
                            RepositoryResultRow(repository: repository)
                        }
                    } header: {
                        Text(countLabel(state.totalCount))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func autocompleteList(state: SearchState) -> some View {
        List {
            ForEach(state.autocompleteCandidates) { item in
                Button {
                    container.send(.tapAutocompleteSuggestion(item))
                } label: {
                    HStack {
                        Text(item.query)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(Self.shortDateFormatter.string(from: item.searchedAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func recentSection(state: SearchState) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("최근 검색")
                    .font(.headline)
                Spacer()
                if !state.recentSearches.isEmpty {
                    Button("전체삭제") {
                        container.send(.clearAllRecentSearches)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.pink)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if state.recentSearches.isEmpty {
                Text("최근 검색 내역이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            } else {
                ForEach(state.recentSearches) { item in
                    HStack {
                        Button {
                            container.send(.tapRecentSearch(item))
                        } label: {
                            Text(item.query)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)

                        Button {
                            container.send(.removeRecentSearch(item.id))
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }

            Divider()
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func countLabel(_ total: Int) -> String {
        let n = NSNumber(value: total)
        let formatted = Self.countFormatter.string(from: n) ?? "\(total)"
        return "\(formatted)개 저장소"
    }
}

#Preview {
    SearchView(container: SearchContainer())
}
