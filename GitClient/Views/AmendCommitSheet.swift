//
//  Untitled.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/09.
//

import SwiftUI

struct AmendCommitSheet: View {
    var folder: Folder
    @Binding var showingAmendCommitAt: Commit?
    var onCreate: (() -> Void)
    @State private var message = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Amend commit with a new message")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    TextEditor(text: $message)
                }
                HStack {
                    Button("Cancel") {
                        showingAmendCommitAt = nil
                    }
                    Spacer()
                    Button("Amend") {
                        Task {
                            do {
                                try await Process.output(
                                    GitCommitAmend(directory: folder.url, message: message)
                                )
                                onCreate()
                                showingAmendCommitAt = nil
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .disabled(message.isEmpty)
                    .keyboardShortcut(.init(.return))
                }
                .padding(.top)
            }
            .frame(width: 400)
            .padding()
        }
        .padding()
        .cornerRadius(8)
        .task {
            message = showingAmendCommitAt?.rawBody ?? ""
        }
        .errorAlert($error)
    }
}
