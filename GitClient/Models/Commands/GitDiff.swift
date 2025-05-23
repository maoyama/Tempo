//
//  GitDiff.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/26.
//

import Foundation

struct GitDiff: Git {
    typealias OutputModel = String
    var arguments: [String] {
        var args = [
            "git",
            "diff",
        ]
        if noRenames {
            args.append("--no-renames")
        }
        if shortstat {
            args.append("--shortstat")
        }
        if cached {
            args.append("--cached")
        }
        if !commitRange.isEmpty {
            args.append(commitRange)
        }
        return args
    }
    var directory: URL
    var noRenames = true
    var shortstat = false
    var cached = false
    var commitRange = ""

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
