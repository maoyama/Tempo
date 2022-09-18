//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

struct ContentView: View {
    private var folders = [
        Folder(path: "GitClient"),
        Folder(path: "GitClient2"),
        Folder(path: "GitClient3"),
    ]
    private var commits = [
        "GitClient": [Commit(message: "Commit"), Commit(message: "Commit 2"), Commit(message: "Commit 3")],
        "GitClient2": [Commit(message: "Commit2"), Commit(message: "Commit2 2"), Commit(message: "Commit2 3")],
        "GitClient3": [Commit(message: "Commit3"), Commit(message: "Commit3 2"), Commit(message: "Commit3 3")],
    ]

    var body: some View {
        NavigationView {
            List(folders, id: \.path) { folder in
                NavigationLink(folder.path) {
                    NavigationView {
                        List(commits[folder.path]!) { commit in
                            NavigationLink(commit.message) {
                                VStack {
                                    Text(commit.message)
                                    Text(commit.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
