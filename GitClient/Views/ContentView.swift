//
//  ContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/17.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(AppStorageKey.folder.rawValue) var folders: Data?
    private var decodedFolders: [Folder] {
        guard let folders else { return [] }
        do {
           return try JSONDecoder().decode([Folder].self, from: folders)
        } catch {
            return []
        }
    }
    @State private var selectionFolderURL: URL?
    private var selectionFolder: Folder? {
        guard let selectionFolderURL = selectionFolderURL else { return nil}
        return decodedFolders.first(where: { $0.url == selectionFolderURL })
    }
    @State private var selectionLog: Log?
    @State private var folderIsRefresh = false
    @State private var lastSyncDate: Date?
    @State private var error: Error?

    var body: some View {
        NavigationSplitView {
            List(decodedFolders, id: \.url, selection: $selectionFolderURL) { folder in
                Label(folder.displayName, systemImage: "folder")
                    .help(folder.url.path)
                    .contextMenu {
                        Button("Delete") {
                            var folders = decodedFolders
                            folders.removeAll { $0 == folder }
                            do {
                                try self.folders = JSONEncoder().encode(folders)
                            } catch {
                                self.error = error
                            }
                        }
                    }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.canCreateDirectories = false
                        panel.begin { (response) in
                            if response == .OK {
                                for fileURL in panel.urls {
                                    let chooseFolder = Folder(url: fileURL)
                                    var folders = decodedFolders
                                    folders.removeAll { $0 == chooseFolder }
                                    folders.insert(chooseFolder, at: 0)
                                    do {
                                        try self.folders = JSONEncoder().encode(folders)
                                    } catch {
                                        self.error = error
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus.rectangle.on.folder")
                    }
                    .help("Add project folder")
                }
            }
        } content: {
            if let folder = selectionFolder {
                FolderView(
                    folder: folder,
                    logStore: LogStore(directory: folder.url),
                    selectionLog: $selectionLog,
                    isRefresh: $folderIsRefresh,
                    lastSyncDate: $lastSyncDate
                )
                .id(folder)
            } else {
                Text("No Folder Selection")
                    .foregroundColor(.secondary)
            }
        } detail: {
            switch selectionLog {
            case .notCommitted:
                CommitCreateView(
                    folder: selectionFolder!,
                    isRefresh: $folderIsRefresh,
                    onCommit: {
                        selectionLog = nil
                        folderIsRefresh = true
                    },
                    onStash: {
                        selectionLog = nil
                        folderIsRefresh = true
                    }
                )
            case .committed(let commit):
                CommitDetailStackView(commit: commit, folder: selectionFolder!)                    .id(selectionLog!.commit!.hash + selectionLog!.commit!.branches.joined() + selectionLog!.commit!.tags.joined())

            case nil:
                Text("No Selection")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 300)
        .onChange(of: selectionFolder, {
            selectionLog = nil
        })
        .errorAlert($error)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
