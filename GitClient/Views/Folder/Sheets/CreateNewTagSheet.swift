//
//  CreateNewTagSheet.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/21.
//

import SwiftUI

struct CreateNewTagSheet: View {
    var folder: Folder
    @Binding var showingCreateNewTagAt: Commit?
    var onCreate: (() -> Void)
    @State private var newTagname = ""
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Create New Tag")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .trailing) {
                        Text("Commit:")
                        Text("Tag Name:")
                            .padding(.vertical, 2)
                    }
                    VStack(alignment: .leading) {
                        Text(showingCreateNewTagAt?.hash ?? "")
                            .textSelection(.enabled)
                            .padding(.horizontal, 4)
                        TextField("New tag name", text: $newTagname)
                            .disabled(isLoading)
                    }
                }

                HStack {
                    Button("Cancel") {
                        showingCreateNewTagAt = nil
                    }
                    Spacer()
                    Button("Create") {
                        Task {
                            do {
                                try await Process.output(
                                    GitTagCreate(
                                        directory: folder.url,
                                        tagname: newTagname,
                                        object: showingCreateNewTagAt!.hash
                                    )
                                )
                                onCreate()
                                showingCreateNewTagAt = nil
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .disabled(newTagname.isEmpty)
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.4)
                            .frame(width: 102, height: 17)
                    } else {
                        Button("Create & Push") {
                            Task {
                                isLoading = true
                                do {
                                    try await Process.output(
                                        GitTagCreate(
                                            directory: folder.url,
                                            tagname: newTagname,
                                            object: showingCreateNewTagAt!.hash
                                        )
                                    )
                                    try await Process.output(
                                        GitPush(directory: folder.url, refspec: newTagname)
                                    )
                                    onCreate()
                                    showingCreateNewTagAt = nil
                                } catch {
                                    isLoading = false
                                    self.error = error
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.init(.return))
                        .disabled(newTagname.isEmpty)
                    }
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
