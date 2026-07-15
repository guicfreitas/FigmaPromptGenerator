import Foundation

struct OpenAIService {
    enum ServiceError: LocalizedError {
        case missingAPIKey, invalidImage, invalidResponse, timedOut, api(String)
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: "Add an OpenAI API key in Settings before generating."
            case .invalidImage: "The selected image could not be encoded."
            case .invalidResponse: "OpenAI returned an unreadable response."
            case .timedOut: "OpenAI did not respond within 90 seconds. Try a smaller screenshot or a shorter CSS block, then try again."
            case .api(let message): message
            }
        }
    }

    func generate(apiKey: String, model: String, imageData: Data, mimeType: String, css: String, notes: String, template: PromptTemplate, temperature: Double, maxTokens: Int) async throws -> String {
        guard !apiKey.isEmpty else { throw ServiceError.missingAPIKey }
        guard let imageURL = dataURL(data: imageData, mimeType: mimeType) else { throw ServiceError.invalidImage }
        let systemInstructions = loadInstructions()
        let userBrief = """
        Generate an implementation prompt for the selected template: \(template.rawValue).

        Optional Figma Inspect CSS:
        \(css.isEmpty ? "Not provided." : css)

        Optional notes:
        \(notes.isEmpty ? "Not provided." : notes)
        """
        var body: [String: Any] = [
            "model": model,
            "instructions": systemInstructions,
            "input": [[
                "role": "user",
                "content": [
                    ["type": "input_text", "text": userBrief],
                    ["type": "input_image", "image_url": imageURL]
                ]
            ]],
            "max_output_tokens": maxTokens
        ]
        if !model.lowercased().hasPrefix("gpt-5") {
            body["temperature"] = temperature
        }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 90
        configuration.timeoutIntervalForResource = 120
        let session = URLSession(configuration: configuration)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw ServiceError.timedOut
        }
        guard let http = response as? HTTPURLResponse else { throw ServiceError.invalidResponse }
        guard 200..<300 ~= http.statusCode else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
            throw ServiceError.api(message?["message"] as? String ?? "OpenAI request failed (\(http.statusCode)).")
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let content = decoded.output?.flatMap { $0.content ?? [] } ?? []
        guard let output = content.first(where: { $0.type == "output_text" })?.text, !output.isEmpty else {
            throw ServiceError.invalidResponse
        }
        return output
    }

    private func dataURL(data: Data, mimeType: String) -> String? {
        "data:\(mimeType);base64,\(data.base64EncodedString())"
    }

    private func loadInstructions() -> String {
        guard let url = Bundle.main.url(forResource: "instruction", withExtension: "md"),
              let text = try? String(contentsOf: url) else {
            return "Create a detailed, English-only implementation prompt. Never write code. Include Objective, Layout, Content, Visual Style, Animations, Hover Interactions, Responsive Behavior, Reuse Existing Components, Design Goals, and Acceptance Criteria."
        }
        return text
    }

    private struct Response: Decodable {
        let output: [Output]?
        struct Output: Decodable {
            let content: [Content]?
        }
        struct Content: Decodable {
            let type: String
            let text: String?
        }
    }
}
