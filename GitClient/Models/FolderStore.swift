//
//  FolderStore.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/21.
//

import Foundation

final class FolderStore: ObservableObject {
    @Published private(set) var folders: [Folder] = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults.standard) throws {
        self.defaults = defaults
        guard let data = defaults.data(forKey: .folder) else
             {
            throw GenericError(errorDescription: "The data object associated with the specified key, or nil if the key does not exist or its value is not a data object.")
        }
        let decoder = JSONDecoder()
        folders = try decoder.decode([Folder].self, from: data)
    }

    func add(_ folder: Folder) throws {
        folders.insert(folder, at: 0)
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(folders)
        defaults.set(encoded, forKey: .folder)
    }
}
