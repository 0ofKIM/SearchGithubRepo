//
//  SearchBarView.swift
//  SearchGithubRepo
//

import SwiftUI

struct SearchBarView: View {
    @FocusState.Binding var fieldFocused: Bool
    @Binding var text: String
    var onSubmit: () -> Void
    var onClear: () -> Void
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("저장소 검색", text: $text)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .focused($fieldFocused)
                    .onSubmit(onSubmit)

                if !text.isEmpty {
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

            if fieldFocused {
                Button("취소", action: onCancel)
                    .foregroundStyle(Color.purple)
                    .buttonStyle(.plain)
            }
        }
    }
}
