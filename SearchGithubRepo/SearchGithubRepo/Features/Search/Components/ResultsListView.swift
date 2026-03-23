//
//  ResultsListView.swift
//  SearchGithubRepo
//

import SwiftUI

struct ResultsListView: View {
    let state: SearchState
    let onTapRepository: (RepositoryDTO) -> Void
    let onPrefetchNextPage: () -> Void
    let countLabelText: String

    var body: some View {
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
                        ForEach(Array(state.repositories.enumerated()), id: \.element.id) { index, repository in
                            Button {
                                onTapRepository(repository)
                            } label: {
                                RepositoryResultRow(repository: repository)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                let endPointIndex = max(0, state.repositories.count - 10)
                                if index == endPointIndex {
                                    onPrefetchNextPage()
                                }
                            }
                        }
                    } header: {
                        Text(countLabelText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    } footer: {
                        if state.isPaginating {
                            HStack {
                                Spacer()
                                Image(systemName: "progress.indicator")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .symbolEffect(.rotate, options: .repeating, isActive: true)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
