//
//  SearchBarView.swift
//  SearchGithubRepo
//

import SwiftUI

struct SearchBarView: View {
    @FocusState.Binding var isSearchFieldFocused: Bool
    @Binding var searchText: String
    var onSubmit: () -> Void
    var onClear: () -> Void
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("저장소 검색", text: $searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .focused($isSearchFieldFocused)
                    .onSubmit(onSubmit)

                if !searchText.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if isSearchFieldFocused {
                Button("취소", action: onCancel)
                    .foregroundStyle(Color.purple)
                    .buttonStyle(.plain)
            }
        }
    }
}
