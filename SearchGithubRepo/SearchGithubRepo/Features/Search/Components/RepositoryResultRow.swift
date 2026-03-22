//
//  RepositoryResultRow.swift
//  SearchGithubRepo
//

import SwiftUI

struct RepositoryResultRow: View {
    let repository: Repository

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AsyncImage(url: URL(string: repository.owner.avatarURL)) { phase in
                switch phase {
                case .empty:
                    Color(.systemGray5)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                case .success(let loadedImage):
                    loadedImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                case .failure:
                    Image(systemName: "photo")
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(repository.owner.login)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
