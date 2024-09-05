//
//  DiffView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/05/26.
//

import SwiftUI

struct NotCommittedDiffView: View {
    var title: String
    var fileDiffs: [FileDiff]
    var staged: Bool
    var onSelect: ((FileDiff, Chunk?) -> Void)?

    var body: some View {
        LazyVStack(alignment: .leading, pinnedViews: .sectionHeaders) {
            Section {
                ForEach(fileDiffs) { fileDiff in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(fileDiff.header)
                                .fontWeight(.bold)
                            ForEach(fileDiff.extendedHeaderLines, id: \.self) { line in
                                Text(line)
                                    .fontWeight(.bold)
                            }
                            ForEach(fileDiff.fromFileToFileLines, id: \.self) { line in
                                Text(line)
                                    .fontWeight(.bold)
                            }
                        }
                        Spacer()
                        if fileDiff.chunks.isEmpty {
                            Button {
                                onSelect?(fileDiff, nil)
                            } label: {
                                Image(systemName: staged ? "minus.circle" : "plus.circle")
                            }
                            .buttonStyle(.accessoryBar)
                            .padding()
                        }
                    }

                    ForEach(fileDiff.chunks) { chunk in
                        HStack {
                            chunkView(chunk)
                            Spacer()
                            Button {
                                onSelect?(fileDiff, chunk)
                            } label: {
                                Image(systemName: staged ? "minus.circle" : "plus.circle")
                            }
                            .buttonStyle(.accessoryBar)
                            .padding()
                        }

                    }
                }
                .font(Font.system(.body, design: .monospaced))
                .padding([.trailing, .bottom, .leading])
            } header: {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(title)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                }
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
    }

    private func chunkView(_ chunk: Chunk) -> some View {
        chunk.lines.map { line in
            Text(line.raw)
                .foregroundStyle(chunkLineColor(line))
        }
        .reduce(Text("")) { partialResult, text in
            partialResult + text + Text("\n")
        }
    }

    private func chunkLineColor(_ line: Chunk.Line) -> Color {
        switch line.kind {
        case .removed:
            return .red
        case .added:
            return .green
        case .unchanged:
            return .primary
        }
    }
}

//#Preview {
//    let text = """
//diff --git a/GitClient.xcodeproj/project.pbxproj b/GitClient.xcodeproj/project.pbxproj
//index 96134c5..46cd844 100644
//--- a/GitClient.xcodeproj/project.pbxproj
//+++ b/GitClient.xcodeproj/project.pbxproj
//@@ -41,7 +41,7 @@
//                61E290D328E1EFC600BCEB04 /* GitDiff.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D228E1EFC600BCEB04 /* GitDiff.swift */; };
//                61E290D528E1F05000BCEB04 /* GitDiffCached.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D428E1F05000BCEB04 /* GitDiffCached.swift */; };
//                61E290D728E5D84100BCEB04 /* GitPush.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290D628E5D84100BCEB04 /* GitPush.swift */; };
//-               61E290DB28E7C66300BCEB04 /* DiffView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290DA28E7C66200BCEB04 /* DiffView.swift */; };
//+               61E290DB28E7C66300BCEB04 /* CommitView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61E290DA28E7C66200BCEB04 /* CommitView.swift */; };
//                61EBD7CF28E922510009ED92 /* GitBranch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7CE28E922510009ED92 /* GitBranch.swift */; };
//                61EBD7D128E940C30009ED92 /* Branch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7D028E940C30009ED92 /* Branch.swift */; };
//                61EBD7D328E966190009ED92 /* GitSwitch.swift in Sources */ = {isa = PBXBuildFile; fileRef = 61EBD7D228E966190009ED92 /* GitSwitch.swift */; };
//"""
//    return NotCommittedDiffView(fileDiffs: try! Diff(raw: text).updateAll(stage: true).fileDiffs)
//}
