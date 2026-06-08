//
//  AnthropicClient.swift
//  FitnessPro
//
//  Minimal Anthropic Messages API client. Uses tool-use ("forced tool")
//  so the model must return a single structured JSON object matching our
//  schema — far more reliable than parsing free-form text.
//
//  Docs contract: POST https://api.anthropic.com/v1/messages
//    headers: x-api-key, anthropic-version: 2023-06-01, content-type: json
//

import Foundation

struct AnthropicClient: Sendable {
    let apiKey: String
    let model: String
    nonisolated(unsafe) private let session: URLSession

    /// Default to Haiku 4.5 — cheap & fast, ideal for structured generation.
    init(apiKey: String,
         model: String = "claude-haiku-4-5-20251001",
         session: URLSession = .shared) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    struct Tool {
        let name: String
        let description: String
        let inputSchema: [String: Any]   // JSON Schema object
    }

    /// Sends one message and forces `tool`. Returns the tool_use `input`
    /// object serialized back to Data, ready to decode into a DTO.
    func toolCall(system: String, user: String, tool: Tool, maxTokens: Int = 3072) async throws -> Data {
        guard !apiKey.isEmpty else { throw PlanGenerationError.missingAPIKey }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [["role": "user", "content": user]],
            "tools": [[
                "name": tool.name,
                "description": tool.description,
                "input_schema": tool.inputSchema
            ]],
            "tool_choice": ["type": "tool", "name": tool.name]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw PlanGenerationError.emptyResponse
        }

        // Pull the tool_use block's `input` out of the content array.
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = root["content"] as? [[String: Any]],
            let toolBlock = content.first(where: { ($0["type"] as? String) == "tool_use" }),
            let input = toolBlock["input"]
        else {
            throw PlanGenerationError.emptyResponse
        }
        return try JSONSerialization.data(withJSONObject: input)
    }
}
