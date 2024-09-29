//
//  AIService.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/29.
//

import Foundation

struct AIService {
    struct CommitMessageProperties: Codable {
        struct CommitMessage: Codable {
            var type = "string"
        }
        var commitMessage = CommitMessage()
    }

    struct Schema<T: Codable>: Codable {
        var type = "object"
        var properties: T
        var required: [String]
        var additionalProperties = false
    }
    struct JSONSchema<T: Codable>: Codable {
        var name: String
        var schema: Schema<T>
        var strict = true
    }
    struct ResponseFormat<T: Codable>: Codable {
        var type = "json_schema"
        var jsonSchema: JSONSchema<T>

        enum CodingKeys: String, CodingKey {
            case type
            case jsonSchema = "json_schema"
        }
    }
    struct Message: Codable {
        var role: String
        var content: String
    }
    struct RequestBody<T: Codable>: Codable {
        var model = "gpt-4o-mini"
        var messages: [Message]
        var responseFormat: ResponseFormat<T>

        enum CodingKeys: String, CodingKey {
            case model
            case messages
            case responseFormat = "response_format"
        }
    }

    struct GeneratedCommiMessage: Codable {
        var commitMessage: String
    }
    struct Choice: Codable {
        struct Message: Codable {
            var content: String
            var refusal: String?
        }
        var message: Message
    }
    struct Response: Codable {
        var choices: [Choice]
    }

    var bearer: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private var jsonEncoder: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        return jsonEncoder
    }

    func commitMessage(stagedDiff: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        let body = RequestBody(
            messages: [
                .init(role: "system", content: "Tell me commit message of this changes for git."),
                .init(role: "user", content: stagedDiff)
            ],
            responseFormat: .init(
                jsonSchema: .init(
                    name: "generated_git_commit_message",
                    schema: Schema(properties: CommitMessageProperties(), required: ["commitMessage"])
                )
            )
        )
        let bodyData = try jsonEncoder.encode(body)
        request.httpBody = bodyData
        if let jsonString = String(data: bodyData, encoding: .utf8) {
            print(jsonString)
        }
        let data = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data.0))
        let response = try JSONDecoder().decode(Response.self, from: data.0)
        guard response.choices.count > 0 else {
            throw GenericError(errorDescription: "OpenAI API response error")
        }
        if let refusal = response.choices[0].message.refusal, !refusal.isEmpty {
            throw GenericError(errorDescription: "OpenAI API refusal error: " + refusal)
        }
        guard let contentData = response.choices[0].message.content.data(using: .utf8) else {
            throw GenericError(errorDescription: "API Response handling error")
        }
        let message = try JSONDecoder().decode(GeneratedCommiMessage.self, from: contentData)
        return message.commitMessage
    }
}
