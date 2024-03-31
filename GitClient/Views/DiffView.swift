//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/01.
//

// test3
import SwiftUI

struct DiffView: View {
    var diff: String
    var folder: Folder
    @State private var commitMessage = ""
    @State private var error: Error?
    var onCommit: ()->Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Text(diff)
                    .textSelection(.enabled)
                    .font(Font.system(.body, design: .monospaced))
                    .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .background(Color(NSColor.textBackgroundColor))
            Divider()
            HStack (spacing:0) {
                ZStack {
                    TextEditor(text: $commitMessage)
                        .padding(8)
                    if commitMessage.isEmpty {
                        Text("Enter commit message here")
                            .foregroundColor(.secondary)
                            .allowsHitTesting(false)
                    }
                }
                Divider()
                Button("Commit") {
                    Task {
                        do {
                            gitAddInteractive()
                            //                            try await Process.output(GitAdd(directory: folder.url))
//                            try await Process.output(GitCommit(directory: folder.url, message: commitMessage))
//                            onCommit()
                        } catch {
                            print(error)
                            self.error = error
                        }
                    }
                }
                .keyboardShortcut(.init(.return))
                .errorAlert($error)
                .disabled(commitMessage.isEmpty)
                .padding()
            }
            .frame(height: 100)
            .background(Color(NSColor.textBackgroundColor))
        }
    }

    func runGitCommand(arguments: [String], input: String? = nil) -> String? {
        let task = Process()
        let pipe = Pipe()
        let inputPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = arguments
        task.currentDirectoryURL = folder.url
        task.standardOutput = pipe
        task.standardInput = inputPipe

        do {
            try task.run()
            inputPipe.fileHandleForWriting.write(input?.data(using: .utf8) ?? Data())
            inputPipe.fileHandleForWriting.closeFile()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error running git command: \(error)")
            return nil
        }
    }

    func gitAddInteractive() {
        if let output = runGitCommand(arguments: ["add", "-p"], input: "y\n") {
            print(output)
        } else {
            print("Failed to run git add -p")
        }
    }

}


struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView(diff: """
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
// test
