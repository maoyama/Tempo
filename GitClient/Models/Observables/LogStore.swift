//
//  LogStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/03.
//

import Foundation
import Observation

@MainActor
@Observable class LogStore {
    var number = 100
    var directory: URL?
    private var grep: [String] {
        searchTokens.filter { token in
            switch token.kind {
            case .grep, .grepAllMatch:
                return true
            default:
                return false
            }
        }.map { $0.text }
    }
    private var grepAllMatch: Bool {
        searchTokens.contains { $0.kind == .grepAllMatch }
    }
    private var s: String {
        searchTokens.filter { $0.kind == .s }.map { $0.text }.first ?? ""
    }
    private var g: String {
        searchTokens.filter { $0.kind == .g }.map { $0.text }.first ?? ""
    }
    private var authors: [String] {
        searchTokens.filter { $0.kind == .author }.map { $0.text }
    }
    private var searchTokenRevisionRange: String {
        searchTokens.filter { $0.kind == .revisionRange }.map { $0.text }.first ?? ""
    }
    private var paths: [String] {
        searchTokens.filter { $0.kind == .path }.map { $0.text }
    }

    var searchTokens: [SearchToken] = []
    var commits: [Commit] = []
    var notCommitted: NotCommitted?
    var totalCommitsCount: Int? = nil
    var canLoadMore: Bool {
        guard let totalCommitsCount else { return false }
        return totalCommitsCount > commits.count
    }
    var error: Error?

    private func gitLog(directory: URL, number: Int=0, revisionRange: String="") -> GitLog {
        GitLog(
            directory: directory,
            number: number,
            revisionRange: revisionRange,
            grep: grep,
            grepAllMatch: grepAllMatch,
            s: s,
            g: g,
            authors: authors,
            paths: paths
        )
    }

    func logs() -> [Log] {
        var logs = commits.map { Log.committed($0) }
        if let notCommitted, !notCommitted.isEmpty {
            logs.insert(.notCommitted, at: 0)
        }
        return logs
    }

    /// 最新500件取得しlogsを差し替え(SearchTokennoRevisionRangeがない場合)
    func refresh() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            return
        }
        do {
            notCommitted = try await notCommitted(directory: directory)
            guard searchTokenRevisionRange.isEmpty else {
                commits = try await loadCommitsWithSearchTokenRevisionRange(directory: directory, revisionRange: searchTokenRevisionRange)
                try await loadTotalCommitsCount()
                return
            }
            commits = try await Process.output(gitLog(directory: directory, number: number))
            try await loadTotalCommitsCount()
        } catch {
            self.error = error
        }
    }

    /// revisionRangeをSearchTokenで利用するための別メソッド
    private func loadCommitsWithSearchTokenRevisionRange(directory: URL, revisionRange: String) async throws -> [Commit] {
        try await Process.output(gitLog(directory: directory, revisionRange: revisionRange))
    }

    /// logsを全てを最新に更新しlogs.first以降のコミットを取得し追加(SearchTokenのRevisionRangeがない場合)
    func update() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            return
        }

        do {
            notCommitted = try await notCommitted(directory: directory)
            guard searchTokenRevisionRange.isEmpty else {
                commits = try await loadCommitsWithSearchTokenRevisionRange(directory: directory, revisionRange: searchTokenRevisionRange)
                return
            }
            let current = try await Process.output(gitLog(
                directory: directory,
                number: commits.count,
                revisionRange: commits.first?.hash ?? ""
            ))
            let adding = try await Process.output(gitLog(
                directory: directory,
                revisionRange: commits.first.map { $0.hash + ".."} ?? ""
            ))
            commits = adding + current
            try await loadTotalCommitsCount()
        } catch {
            self.error = error
        }
    }

    func removeAll() {
        commits = []
        notCommitted = nil
        totalCommitsCount = nil
    }

    /// logビューの表示時に呼び出しし必要に応じてlogsを追加読み込み
    func logViewTask(_ log: Log) async {
        switch log {
        case .notCommitted:
            return
        case .committed(let commit):
            if commit == commits.last, searchTokenRevisionRange.isEmpty {
                await loadMore()
            }
        }
    }

    func nextLogID(logID: String) -> String? {
        if logID == Log.notCommitted.id {
            return commits.first?.id
        }
        let index = commits.firstIndex { $0.id == logID }
        guard let index, index + 1 < commits.count else { return nil }
        return commits[index + 1].id
    }

    func previousLogID(logID: String) -> String? {
        if logID == Log.notCommitted.id {
            return nil
        }
        let index = commits.firstIndex { $0.id == logID }
        guard let index else { return nil }
        if index == 0 {
            if let notCommitted, !notCommitted.isEmpty {
                return Log.notCommitted.id
            }
            return nil
        }
        return commits[index - 1].id
    }

    private func notCommitted(directory: URL) async throws -> NotCommitted {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let status = try await Process.output(GitStatus(directory: directory))
        return NotCommitted(diff: gitDiff, diffCached: gitDiffCached, status: status)
    }
    /// logs.last以前のコミットを取得し追加
    func loadMore() async {
        guard let last = commits.last, let directory else { return }
        do {
            // revisionRangeをlast.hash^で指定すると最初のコミットに到達した際に存在しないのでunknown revisionとエラーになる
            // なのでlast.hashで指定し重複する最初の要素をドロップする
            commits += try await Process.output(gitLog(
                directory: directory,
                number: number + 1,
                revisionRange: last.hash
            )).dropFirst()
        } catch {
            self.error = error
        }
    }

    private func loadTotalCommitsCount() async throws {
        guard let directory else { return }
        if searchTokens.isEmpty {
            totalCommitsCount = try await Process.output(GitRevListCount(directory: directory))
        } else {
            totalCommitsCount = try await Process.output(gitLog(
                directory: directory,
                revisionRange: searchTokenRevisionRange
            )).count
        }
    }
}
