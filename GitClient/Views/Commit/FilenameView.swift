//
//  FilenameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FilenameView: View {
    var toFilePath: String
    var filePathDisplay: String

    var body: some View {
        HStack {
            if let asset = Language.assetName(filePath: toFilePath) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
            } else {
                Image(systemName: "doc")
                    .frame(width: 20, height: 20)
                    .fontWeight(.heavy)
            }
            Text(filePathDisplay)
                .fontWeight(.bold)
                .font(Font.system(.body, design: .default))
        }
    }
}

#Preview {
    HStack {
        FilenameView(
            toFilePath: "Sources/MyFeature/File.swift",
            filePathDisplay: "Sources/MyFeature/File.swift"
        )
        Spacer()
    }
    HStack {
        FilenameView(
            toFilePath: "Sources/MyFeature/File.pbj",
            filePathDisplay: "Sources/MyFeature/File.pbj"
        )
        Spacer()
    }
}
