//
//  GitPull.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/03/01.
//

import Foundation

struct GitPull: Git {
    typealias OutputModel = Void
    var arguments = [
        "git",
        "pull",
    ]
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}
