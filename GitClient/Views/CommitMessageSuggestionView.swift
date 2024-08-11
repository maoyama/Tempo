//
//  MessageTemplateSuggestionView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/08/10.
//

import SwiftUI
import Collections

struct CommitMessageSuggestionView: View {
    @State private var error: Error?
    @State private var isPresenting = false
    @Environment(\.openWindow) private var openWindow
    @AppStorage (AppStorageKey.commitMessageTemplate.rawValue) var commitMessageTemplate: Data = AppStorageDefaults.commitMessageTemplate
    var decodedCommitMessageTemplate: Array<String> {
        do {
            do {
                return try JSONDecoder().decode(Array<String>.self, from: commitMessageTemplate)
            } catch {
                return []
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(decodedCommitMessageTemplate, id: \.self) { template in
                        Button(template) {
                            NotificationCenter.default.post(name: .didSelectCommitMessageTemplateNotification, object: template)
                        }
                        .buttonStyle(.borderless)
                        if template != decodedCommitMessageTemplate.last {
                            Text("|")
                                .foregroundStyle(.separator)
                        }
                    }
                }
                .padding(.leading, 14)
            }
            .frame(height: 44)
            Button(action: {
                openWindow(id: WindowID.commitMessageTemplates.rawValue)
            }, label: {
                Image(systemName: "list.dash")
            })
            .padding([.horizontal], 14)
        }
        .errorAlert($error)
    }
}

#Preview {
    CommitMessageSuggestionView()
}
