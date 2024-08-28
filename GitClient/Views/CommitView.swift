//
//  CommitView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

import SwiftUI

struct CommitView: View {
    var diffRaw: String
    var folder: Folder
    @State private var runTask = false
    @State private var fileDiffs: [FileDiff] = []
    @State private var commitMessage = ""
    @State private var error: Error?
    @State private var isAmend = false
    @State private var amendCommit: Commit?
    var onCommit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if runTask {
                    if !fileDiffs.isEmpty {
                        HStack {
                            VStack(alignment: .leading) {
                                NotCommittedDiffView(fileDiffs: fileDiffs) { fileDiff, chunk in
                                }
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        Text(diffRaw)
                            .padding()
                    }
                }
            }
            .textSelection(.enabled)
            .font(Font.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .background(Color(NSColor.textBackgroundColor))
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    ZStack {
                            TextEditor(text: $commitMessage)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                            if commitMessage.isEmpty {
                                Text("Enter commit message here")
                                    .foregroundColor(.secondary)
                                    .allowsHitTesting(false)
                            }
                    }
                    .frame(height: 80)
                    CommitMessageSuggestionView()
                }
                Divider()
                VStack(spacing: 14) {
                    Button("Commit") {
                        Task {
                            do {
                                try await Process.output(GitAdd(directory: folder.url))
                                if isAmend {
                                    try await Process.output(GitCommitAmend(directory: folder.url, message: commitMessage))
                                } else {
                                    try await Process.output(GitCommit(directory: folder.url, message: commitMessage))
                                }
                                onCommit()
                            } catch {
                                self.error = error
                            }
                        }
                    }
                    .keyboardShortcut(.init(.return))
                    .disabled(commitMessage.isEmpty)
                    Toggle("Amend", isOn: $isAmend)
                        .font(.caption)
                }
                .onChange(of: isAmend) {
                    if isAmend {
                        commitMessage = amendCommit?.rawBody ?? ""
                    } else {
                        commitMessage = ""
                    }
                }
                .padding()
            }
            .background(Color(NSColor.textBackgroundColor))
            .onReceive(NotificationCenter.default.publisher(for: .didSelectCommitMessageSnippetNotification), perform: { notification in
                if let commitMessage = notification.object as? String {
                    self.commitMessage = commitMessage
                }
            })
        }
        .task {
            do {
                fileDiffs = try Diff(raw: diffRaw).updateAll(stage: true).fileDiffs
            } catch {
                
            }

            do {
                amendCommit = try await Process.output(GitLog(directory: folder.url)).first
            } catch {
                self.error = error
            }
            runTask = true
        }
    }
}

struct CommitView_Previews: PreviewProvider {
    static var previews: some View {
        CommitView(diffRaw: """
diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
index 0cd5c16..114b4ae 100644
--- a/GitClient/Views/DiffView.swift
+++ b/GitClient/Views/DiffView.swift
@@ -11,11 +11,25 @@ struct DiffView: View {
     var diff: String

     var body: some View {
-        ScrollView {
-            Text(diff)
-                .font(Font.system(.body, design: .monospaced))
-                .frame(maxWidth: .infinity, alignment: .leading)
-                .padding()
+        ZStack {
+            ScrollView {
+                Text(diff)
+                    .textSelection(.enabled)
+                    .font(Font.system(.body, design: .monospaced))
+                    .frame(maxWidth: .infinity, alignment: .leading)
+                    .padding()
+            }
+            VStack {
+                Spacer()
+                HStack {
+                    Spacer()
+                    Button("Commit") {
+
+                    }
+                    .padding()
+                }
+                .background(.ultraThinMaterial)
+            }
         }
     }
 }
diff --git a/GitClient/Views/DiffView.swift b/GitClient/Views/DiffView.swift
index 0cd5c16..114b4ae 100644
--- a/GitClient/Views/DiffView.swift
+++ b/GitClient/Views/DiffView.swift
@@ -11,11 +11,25 @@ struct DiffView: View {
     var diff: String

     var body: some View {
-        ScrollView {
-            Text(diff)
-                .font(Font.system(.body, design: .monospaced))
-                .frame(maxWidth: .infinity, alignment: .leading)
-                .padding()
+        ZStack {
+            ScrollView {
+                Text(diff)
+                    .textSelection(.enabled)
+                    .font(Font.system(.body, design: .monospaced))
+                    .frame(maxWidth: .infinity, alignment: .leading)
+                    .padding()
+            }
+            VStack {
+                Spacer()
+                HStack {
+                    Spacer()
+                    Button("Commit") {
+
+                    }
+                    .padding()
+                }
+                .background(.ultraThinMaterial)
+            }
         }
     }
 }

""", folder: .init(url: .init(string: "file:///maoyama")!), onCommit: {})
    }
}
