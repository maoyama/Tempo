//
//  FileNameView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/06.
//

import SwiftUI

struct FileNameView: View {
    @Environment(\.openURL) private var openURL

    @State var isHover = false
    var toFilePath: String
    var filePathDisplay: String


    var body: some View {
        HStack {
            if let asset = Language.assetName(filePath: toFilePath) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18)
            } else {
                Image(systemName: "doc")
                    .frame(width: 18, height: 18)
                    .fontWeight(.heavy)
            }
            Text(filePathDisplay)
                .fontWeight(.bold)
                .font(Font.system(.body, design: .default))
            if isHover {
                Image(systemName: "arrow.right.circle.fill")
            }
            Spacer()
        }
        .onHover { hover in
            isHover = hover
        }
    }
}

#Preview {

    FileNameView(
        toFilePath: "Sources/MyFeature/File.swift",
        filePathDisplay: "Sources/MyFeature/File.swift"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.py",
        filePathDisplay: "Sources/MyFeature/File.py"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.rb",
        filePathDisplay: "Sources/MyFeature/File.rb"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.rs",
        filePathDisplay: "Sources/MyFeature/File.rs"
    )

    FileNameView(
        toFilePath: "Sources/MyFeature/File.js",
        filePathDisplay: "Sources/MyFeature/File.js"
    )

    FileNameView(
        toFilePath: "Sources/MyFeature/File.ml",
        filePathDisplay: "Sources/MyFeature/File.ml"
    )
    FileNameView(
        toFilePath: "Sources/MyFeature/File.pbj",
        filePathDisplay: "Sources/MyFeature/File.pbj"
    )
}
