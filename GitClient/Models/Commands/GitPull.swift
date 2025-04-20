//
//  GitPull.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/03/01.
//

import Foundation

struct GitPull: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "pull",
            "origin",
            refspec,
        ]
    }
    var directory: URL
    var refspec: String

    func parse(for stdOut: String) -> String {
        return stdOut
    }
}
