//
//  SyncState.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Foundation
import Observation

@MainActor
@Observable class SyncState {
    var folder: Folder?
    var branch: Branch?
    var shouldPull = false
    var shouldPush = false

    func sync() async throws {
        guard let folder, let branch else {
            shouldPull = false
            shouldPush = false
            return
        }
        try await Process.output(GitFetch(directory: folder.url))
        shouldPull = !(try await Process.output(GitLog(directory: folder.url, revisionRange: "\(branch.name)..origin/\(branch.name)" )).isEmpty)
    }
}
