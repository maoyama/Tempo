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
    let number = 500
    var directory: URL?
    private var grep: [String] {
        searchTokens.filter { token in
            switch token.kind {
            case .grep, .grepAllMatch:
                return true
            case .g, .s, .author:
                return false
            }
        }.map { $0.text }
    }
    private var grepAllMatch: Bool {
        searchTokens.contains { $0.kind == .grepAllMatch }
    }
    private var s: String {
        searchTokens.filter { token in
            switch token.kind {
            case .s:
                return true
            default:
                return false
            }
        }.map { $0.text }.first ?? ""

    }
    private var g: String {
        searchTokens.filter { token in
            switch token.kind {
            case .g:
                return true
            default:
                return false
            }
        }.map { $0.text }.first ?? ""
    }
    var searchTokens: [SearchToken] = []
    var commits: [Commit] = []
    var notCommitted: NotCommitted?
    var error: Error?

    func logs() -> [Log] {
        var logs = commits.map { Log.committed($0) }
        if let notCommitted, !notCommitted.isEmpty {
            logs.insert(.notCommitted, at: 0)
        }
        return logs
    }

    /// 最新500件取得しlogsを差し替え
    func refresh() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            return
        }
        do {
            notCommitted = try await notCommited(directory: directory)
            commits = try await Process.output(GitLog(
                directory: directory,
                number: number,
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g
            ))
        } catch {
            self.error = error
        }
    }

    /// logsを全てを最新に更新しlogs.first以降のコミットを取得し追加
    func update() async {
        guard let directory else {
            notCommitted = nil
            commits = []
            return
        }

        do {
            notCommitted = try await notCommited(directory: directory)
            let current = try await Process.output(GitLog(
                directory: directory,
                number: commits.count,
                revisionRange: commits.first?.hash ?? "",
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g
            ))
            let adding = try await Process.output(GitLog(
                directory: directory,
                revisionRange: commits.first.map { $0.hash + ".."} ?? "",
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g
            ))
            commits = adding + current
        } catch {
            self.error = error
        }
    }

    func removeAll() {
        commits = []
        notCommitted = nil
    }

    /// logビューの表示時に呼び出しし必要に応じてlogsを追加読み込み
    func logViewTask(_ log: Log) async {
        switch log {
        case .notCommitted:
            return
        case .committed(let commit):
            if commit == commits.last, let directory {
                await loadMore(directory: directory)
            }
        }
    }

    private func notCommited(directory: URL) async throws -> NotCommitted {
        let gitDiff = try await Process.output(GitDiff(directory: directory))
        let gitDiffCached = try await Process.output(GitDiffCached(directory: directory))
        let status = try await Process.output(GitStatus(directory: directory))
        return NotCommitted(diff: gitDiff, diffCached: gitDiffCached, status: status)
    }

    /// logs.last以前のコミットを取得し追加
    private func loadMore(directory: URL) async {
        guard let last = commits.last else { return }
        do {
            // revisionRangeをlast.hash^で指定すると最初のコミットに到達した際に存在しないのでunknown revisionとエラーになる
            // なのでlast.hashで指定し重複する最初の要素をドロップする
            commits += try await Process.output(GitLog(
                directory: directory,
                number: number + 1,
                revisionRange: last.hash,
                grep: grep,
                grepAllMatch: grepAllMatch,
                s: s,
                g: g
            )).dropFirst()
        } catch {
            self.error = error
        }
    }
}
