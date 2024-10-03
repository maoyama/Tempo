//
//  GitLog.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct GitLog: Git {
    typealias OutputModel = [Commit]
    var arguments: [String] {
        var args = [
            "git",
            "log",
            "--pretty=format:%H"
            + .formatSeparator + "%an"
            + .formatSeparator + "%ar"
            + .formatSeparator + "%s"
            + .formatSeparator + "%B"
            + .formatSeparator + "%D"
            + .componentSeparator,
        ]
        if number > 0 {
            args.append("-\(number)")
        }
        if !revisionRange.isEmpty {
            args.append(revisionRange)
        }
        return args
    }
    var directory: URL
    var number = 0
    var revisionRange = ""

    func parse(for stdOut: String) throws -> [Commit] {
        let logs = stdOut.components(separatedBy: String.componentSeparator + "\n")
        return logs.map { log in
            let separated = log.components(separatedBy: String.formatSeparator)
            let refs: [String]
            if separated[5].isEmpty {
                refs = []
            } else {
                refs = separated[5].components(separatedBy: ", ")
            }
            return Commit(
                hash: separated[0],
                author: separated[1],
                authorDateRelative: separated[2],
                title: separated[3],
                rawBody: separated[4],
                branches: refs.filter { !$0.hasPrefix("tag: ") },
                tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
            )
        }
    }
}

