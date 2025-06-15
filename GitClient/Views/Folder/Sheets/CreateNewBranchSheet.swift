//
//  CreateNewBranchSheet.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/08.
//

import SwiftUI

struct CreateNewBranchSheet: View {
    var folder: Folder
    @Binding var showingCreateNewBranchFrom: Branch?
    var onCreate: (() -> Void)
    @State private var newBranchName = ""
    @State private var error: Error?

    var body: some View {
        VStack {
            Text("Create New Branch")
                .font(.headline)
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .trailing) {
                        Text("from:")
                        Text("to:")
                            .padding(.vertical, 2)
                    }
                    VStack(alignment: .leading) {
                        Text(showingCreateNewBranchFrom?.name ?? "")
                            .textSelection(.enabled)
                            .padding(.horizontal, 4)
                        TextField("New branch name", text: $newBranchName)
                    }
                }
                HStack {
                    Button("Cancel") {
                        showingCreateNewBranchFrom = nil
                    }
                    Spacer()
                    Button("Create") {
                        Task {
                            do {
                                try await Process.output(
                                    GitCheckoutB(directory: folder.url, newBranchName: newBranchName, startPoint: showingCreateNewBranchFrom!.point)
                                )
                                showingCreateNewBranchFrom = nil
                                onCreate()
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

struct CreateNewBranchSheet_Previews: PreviewProvider {
    @State private static var isShowing: Branch? = Branch(name: "hoge", isCurrent: false)

    static var previews: some View {
        CreateNewBranchSheet(
            folder: .init(url: .init(string: "file:///projects/")!),
            showingCreateNewBranchFrom: $isShowing)
            {

        }
    }
}
