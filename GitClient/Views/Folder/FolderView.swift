//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

private struct FolderViewShowing {
    var branches = false
    var createNewBranchFrom: Branch?
    var renameBranch: Branch?
    var stashChanged = false
    var tags = false
    var createNewTagAt: Commit?
    var amendCommitAt: Commit?
}

struct FolderView: View {
    @Environment(\.appearsActive) private var appearsActive
    var folder: Folder
    @Binding var selectionLog: Log?
    @Binding var isRefresh: Bool
    @State private var logStore = LogStore()
    @State private var syncState = SyncState()
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showing = FolderViewShowing()
    @State private var branch: Branch?
    @State private var selectionLogID: String?
    @State private var searchTokens: [SearchToken] = []
    @State private var searchText = ""
    @State private var searchTask: Task<(), Never>?
    @State private var showUpToDatePull = false
    @State private var showUpToDatePush = false

    var body: some View {
        List(logStore.logs(), selection: $selectionLogID) { log in
            logsRow(log)
                .task {
                    await logStore.logViewTask(log)
                }
        }
        .overlay(content: {
            if logStore.commits.isEmpty && !searchTokens.isEmpty  {
                Text("No Commits History")
                    .foregroundColor(.secondary)
            }
        })
        .searchable(text: $searchText, editableTokens: $searchTokens, prompt: "Search Commits", token: { $token in
            Picker(selection: $token.kind) {
                Text("Message").tag(SearchKind.grep)
                Text("Message(A)").tag(SearchKind.grepAllMatch)
                Text("Changed").tag(SearchKind.g)
                Text("Changed(O)").tag(SearchKind.s)
                Text("Author").tag(SearchKind.author)
                Text("Revision Range").tag(SearchKind.revisionRange)
            } label: {
                Text(token.text)
            }
        })
        .searchSuggestions({
            if !searchText.isEmpty {
                Text("Message: " + searchText).searchCompletion(SearchToken(kind: .grep, text: searchText))
                    .help("Search log messages matching the given pattern (regular expression).")
                Text("Message(All Match): " + searchText).searchCompletion(SearchToken(kind: .grepAllMatch, text: searchText))
                    .help("Search log messages matching all given patterns instead of at least one.")
                Text("Changed: " + searchText).searchCompletion(SearchToken(kind: .g, text: searchText))
                    .help("Search commits with added/removed lines that match the specified regex. ")
                Text("Changed(Occurrences): " + searchText).searchCompletion(SearchToken(kind: .s, text: searchText))
                    .help("Search commits where the number of occurrences of the specified regex has changed (added/removed).")
                Text("Author: " + searchText).searchCompletion(SearchToken(kind: .author, text: searchText))
                    .help("Search commits by author matching the given pattern (regular expression).")
                Text("Revision Range: " + searchText).searchCompletion(SearchToken(kind: .revisionRange, text: searchText))
                    .help("Search commits within the revision range specified by Git syntax. e.g., main.., v1.0.0...v2.0.0")
            }
        })
        .task {
            await refreshModels()
        }
        .onChange(of: searchTokens, { oldValue, newValue in
            searchTokens = SearchTokensHandler.handle(oldTokens: oldValue, newTokens: newValue)
            logStore.searchTokens = searchTokens
            searchTask?.cancel()
            searchTask = Task {
                isLoading = true
                await refreshModels()
                isLoading = false
            }
        })
        .onChange(of: selectionLogID, {
            selectionLog = logStore.logs().first { $0.id == selectionLogID }
        })
        .onChange(of: selectionLog, {
            if selectionLog == nil {
                selectionLogID = nil
            }
        })
        .onChange(of: isRefresh, { oldValue, newValue in
            if newValue {
                Task {
                    await refreshModels()
                    isRefresh = false
                }
            }
        })
        .errorAlert($error)
        .errorAlert($logStore.error)
        .sheet(item: $showing.createNewBranchFrom, content: { _ in
            CreateNewBranchSheet(folder: folder, showingCreateNewBranchFrom: $showing.createNewBranchFrom) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showing.renameBranch, onDismiss: {
            Task {
                await updateModels()
            }
        }, content: { _ in
            RenameBranchSheet(folder: folder, showingRenameBranch: $showing.renameBranch)
        })
        .sheet(item: $showing.createNewTagAt, content: { _ in
            CreateNewTagSheet(folder: folder, showingCreateNewTagAt: $showing.createNewTagAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showing.amendCommitAt, content: { _ in
            AmendCommitSheet(folder: folder, showingAmendCommitAt: $showing.amendCommitAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(isPresented: $showing.stashChanged, content: {
            StashChangedView(folder: folder, showingStashChanged: $showing.stashChanged)
        })
        .navigationTitle(branch?.name ?? "")
        .toolbar {
            navigationToolbar()
        }
        .toolbar {
            if isLoading {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
            } else if showUpToDatePull || showUpToDatePush {
                HStack(spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Already up to date")
                }
                .foregroundColor(.green)
                .transition(.opacity)
            } else {
                addBranchButton()
                    .padding(.trailing)
                tagButton()
                stashButton()
                    .padding(.trailing)
                pullButton()
                pushButton()
            }
        }
        .onChange(of: showing.stashChanged) { _, new in
            if !new {
                Task {
                    await updateModels()
                }
            }
        }
        .onChange(of: appearsActive) { _, new in
            if new {
                Task {
                    await updateModels()
                }
            }
        }
    }

    fileprivate func refreshModels() async {
        do {
            branch = try await Process.output(GitBranch(directory: folder.url)).current
            logStore.directory = folder.url
            syncState.folderURL = folder.url
            syncState.branch = branch

            await logStore.refresh()
            if Task.isCancelled {
                throw CancellationError()
            }
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            try await syncState.sync()
        } catch {
            if !Task.isCancelled {
                self.error = error
                branch = nil
                logStore.removeAll()
            }
        }
    }

    fileprivate func updateModels() async {
        do {
            let currentBranch = try await Process.output(GitBranch(directory: folder.url)).current
            guard currentBranch == branch else { // Support for external changes made outside the app (e.g., via CLI)
                await refreshModels()
                return
            }
            await logStore.update()
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            try await syncState.sync()
        } catch {
            self.error = error
        }
    }


    fileprivate func navigationToolbar() -> ToolbarItem<(), some View> {
        return ToolbarItem(placement: .navigation) {
            Button {
                showing.branches.toggle()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Select branch.")
            .popover(isPresented: $showing.branches) {
                TabView {
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        onSelect: { branch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitch(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showing.createNewBranchFrom = from
                        },
                        onSelectRenameBranch: { old in
                            showing.renameBranch = old
                        }
                    )
                        .tabItem {
                            Text("Local")
                        }
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        isRemote: true,
                        onSelect: { branch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitchDetach(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showing.createNewBranchFrom = from
                        }
                    )
                        .tabItem {
                            Text("Remotes")
                        }
                }
                .frame(width: 300, height: 660)
                .padding()
            }
        }
    }

    fileprivate func logsRow(_ log: Log) -> some View {
        return VStack {
            switch log {
            case .notCommitted:
                Text("Not Committed")
                    .foregroundStyle(Color.secondary)
            case .committed(let commit):
                CommitRowView(commit: commit)
                    .contextMenu {
                        Button("Checkout") {
                            Task {
                                do {
                                    try await Process.output(GitCheckout(directory: folder.url, commitHash: commit.hash))
                                    await refreshModels()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Revert" + (commit.parentHashes.count == 2 ? " -m 1 (\(commit.parentHashes[0].prefix(7)))" : "")) {
                            Task {
                                do {
                                    if commit.parentHashes.count == 2 {
                                        try await Process.output(GitRevert(directory: folder.url,  parentNumber: 1, commit: commit.hash))
                                    } else {
                                        try await Process.output(GitRevert(directory: folder.url, commit: commit.hash))
                                    }
                                    await refreshModels()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Tag") {
                            showing.createNewTagAt = commit
                        }
                        if commit == logStore.commits.first {
                            if let notCommitted = logStore.notCommitted {
                                if notCommitted.diffCached.isEmpty {
                                    Button("Amend") {
                                        showing.amendCommitAt = commit
                                    }
                                }
                            } else {
                                Button("Amend") {
                                    showing.amendCommitAt = commit
                                }
                            }
                        }
                    }
            }

        }
    }

    fileprivate func addBranchButton() -> some View {
        Button {
            showing.createNewBranchFrom = branch
        } label: {
            Image(systemName: "plus")
        }
        .help("Create new branch.")
    }

    fileprivate func tagButton() -> some View {
        Button {
            showing.tags.toggle()
        } label: {
            Image(systemName: "tag")
        }
        .help("Show tags.")
        .popover(isPresented: $showing.tags, content: {
            TagsView(folder: folder, showingTags: $showing.tags)
        })
        .onChange(of: showing.tags) { oldValue, newValue in
            if oldValue && !newValue {
                Task {
                    await refreshModels()
                }
            }
        }
    }

    fileprivate func stashButton() -> some View {
        Button {
            showing.stashChanged.toggle()
        } label: {
            Image(systemName: "tray")
        }
        .help("Show stashed changes.")
    }

    fileprivate func badge() -> some View {
        return Circle()
            .fill(Color.accentColor)
            .foregroundColor(.white)
            .frame(width: 6)
            .offset(x: 2, y: -2)
    }
    
    fileprivate func pullButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    // Perform simple pull operation and check result after
                    _ = try await Process.output(GitPull(directory: folder.url, refspec: branch?.name ?? "HEAD"))
                    await refreshModels()
                    
                    // Show notification if there's nothing to pull after refresh
                    if !syncState.shouldPull {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showUpToDatePull = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                            withAnimation {
                                showUpToDatePull = false
                            }
                        }
                    }
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        } label: {
            Image(systemName: "arrow.down")
                .overlay(alignment: .topTrailing, content: {
                    badge()
                        .animation(.default, body: { content in
                            content
                                .opacity(syncState.shouldPull ? 1 : 0)
                        })
                })
        }
        .help("Pull origin \(branch?.name ?? "")." )
    }

    fileprivate func pushButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    // Perform simple push operation and check result after
                    _ = try await Process.output(GitPush(directory: folder.url))
                    await updateModels()
                    
                    // Show notification if there's nothing to push after refresh
                    if !syncState.shouldPush {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showUpToDatePush = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                            withAnimation {
                                showUpToDatePush = false
                            }
                        }
                    }
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        } label: {
            Image(systemName: "arrow.up")
                .overlay(alignment: .topTrailing, content: {
                    badge()
                        .animation(.default, body: { content in
                            content
                                .opacity(syncState.shouldPush ? 1 : 0)
                        })
                })
        }
        .help("Push origin HEAD.")
    }
}

struct CommitsView_Previews: PreviewProvider {
    @State static var selection: Log?
    @State static var refresh = false

    static var previews: some View {
        FolderView(
            folder: .init(url: URL(string: "file:///maoyama/Projects/")!),
            selectionLog: $selection,
            isRefresh: $refresh
        )
    }
}
