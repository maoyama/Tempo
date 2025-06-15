//
//  CommitMessageSnippetView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/11.
//

import SwiftUI

struct CommitMessageSnippetView: View {
    @AppStorage(AppStorageKey.commitMessageSnippet.rawValue) var commitMessageSnippet: Data = AppStorageDefaults.commitMessageSnippets
    var decodedCommitMessageSnippets: Array<String> {
        do {
            return try JSONDecoder().decode(Array<String>.self, from: commitMessageSnippet)
        } catch {
            return []
        }
    }
    @State private var editCommitMessageSnippet: String = ""
    @State private var error: Error?

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach(decodedCommitMessageSnippets, id: \.self) { snippet in
                    HStack {
                        Button(snippet) {
                            NotificationCenter.default.post(name: .didSelectCommitMessageSnippetNotification, object: snippet)
                        }
                            .buttonStyle(.borderless)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                    }
                    .contextMenu {
                        Button("Delete") {
                            var snippets = decodedCommitMessageSnippets
                            snippets.removeAll { $0 == snippet }
                            do {
                                commitMessageSnippet = try JSONEncoder().encode(snippets)
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
                .onMove(perform: { indices, newOffset in
                    var t = decodedCommitMessageSnippets
                    t.move(fromOffsets: indices, toOffset: newOffset)
                    do {
                        commitMessageSnippet = try JSONEncoder().encode(t)
                    } catch {
                        self.error = error
                    }
                })
            }
            Divider()
            HStack(spacing: 0) {
                ZStack {
                    TextEditor(text: $editCommitMessageSnippet)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                    if editCommitMessageSnippet.isEmpty {
                        Text("Enter commit message snippet here")
                            .foregroundColor(.secondary)
                            .allowsHitTesting(false)
                    }
                }
                Divider()
                Button("Add") {
                    let newCommitMessageSnippets = decodedCommitMessageSnippets + [editCommitMessageSnippet]
                    do {
                        commitMessageSnippet = try JSONEncoder().encode(newCommitMessageSnippets)
                        editCommitMessageSnippet = ""
                    } catch {
                        self.error = error
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.init(.return))
                .disabled(editCommitMessageSnippet.isEmpty)
                .padding()
            }
            .frame(height: 80)
            .background(Color(NSColor.textBackgroundColor))
        }
        .errorSheet($error)
    }
}

#Preview {
    CommitMessageSnippetView()
}
