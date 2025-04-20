//
//  GitPush.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/29.
//

import Foundation

struct GitPush: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "push",
            "origin",
            refspec,
        ]
    }
    var directory: URL
    var refspec = "HEAD"

    func parse(for stdOut: String) -> String {
        return stdOut
    }
}
