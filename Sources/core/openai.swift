import Combine
import Foundation

enum OpenAIModel: String {
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
}

enum OpenAIError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError
}

class OpenAIClient {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func generateStreamResponse(prompt: String, model: OpenAIModel) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let endpoint = "\(baseURL)/chat/completions"
                    guard let url = URL(string: endpoint) else {
                        throw OpenAIError.invalidURL
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

                    let requestBody: [String: Any] = [
                        "model": model.rawValue,
                        "messages": [["role": "user", "content": prompt]],
                        "stream": true,
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    let (responseStream, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200 ... 299).contains(httpResponse.statusCode)
                    else {
                        throw OpenAIError.invalidResponse
                    }

                    for try await line in responseStream.lines {
                        if line.hasPrefix("data: "),
                           let data = line.dropFirst(6).data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let content = delta["content"] as? String
                        {
                            continuation.yield(content)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
