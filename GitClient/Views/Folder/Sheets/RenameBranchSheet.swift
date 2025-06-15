//
//  RenameBranchSheet.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/08.
//

import SwiftUI

struct RenameBranchSheet: View {
    var folder: Folder
    @Binding var showingRenameBranch: Branch?
    @State private var newBranchName = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Rename Branch")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .trailing) {
                        Text("Old:")
                        Text("New:")
                            .padding(.vertical, 2)
                    }
                    VStack(alignment: .leading) {
                        Text(showingRenameBranch?.name ?? "")
                            .textSelection(.enabled)
                            .padding(.horizontal, 4)
                        TextField("New branch name", text: $newBranchName)
                    }
                }

                HStack {
                    Button("Cancel") {
                        showingRenameBranch = nil
                    }
                    Spacer()
                    Button("Rename") {
                        Task {
                            do {
                                try await Process.output(
                                    GitBranchRename(directory: folder.url, oldBranchName: showingRenameBranch?.name ?? "", newBranchName: newBranchName)
                                )
                                showingRenameBranch = nil
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.init(.return))
                    .disabled(newBranchName.isEmpty)
                }
                .padding(.top)
            }
            .frame(width: 400)
            .padding()
        }
        .padding()
        .cornerRadius(8)
        .errorSheet($error)
    }
}
