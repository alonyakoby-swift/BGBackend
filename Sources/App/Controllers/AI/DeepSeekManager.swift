// DeepSeekManager.swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineFoundation
#endif

/// A simple manager for calling DeepSeek’s chat-completions endpoint.
public final class DeepSeekManager {
    private let baseURL = "https://api.deepseek.com/"
    private var generatePath: String { baseURL + "v1/chat/completions" }
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// Sends `prompt` to DeepSeek and invokes `completion` with the first choice’s content or an Error.
    public func generateResponse(prompt: String,
                                 completion: @escaping (Result<String, Error>) -> Void)
    {
        guard let url = URL(string: generatePath) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = DeepSeekRequest(
            model: "deepseek-chat",
            messages: [DSMessage(role: "user", content: prompt)],
            temperature: 0.7,
            max_tokens: 2048
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("[DeepSeekManager] Encoding error: \(error)")
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, resp, err in
            if let err = err {
                print("[DeepSeekManager] Network error: \(err)")
                completion(.failure(err))
                return
            }
            guard let http = resp as? HTTPURLResponse, let data = data else {
                let e = URLError(.cannotParseResponse)
                print("[DeepSeekManager] Invalid response")
                completion(.failure(e))
                return
            }
            guard http.statusCode == 200 else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                let e = NSError(domain: "DeepSeekAPI",
                                code: http.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: msg])
                print("[DeepSeekManager] API error (\(http.statusCode)): \(msg)")
                completion(.failure(e))
                return
            }
            do {
                let respObj = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
                if let text = respObj.choices?.first?.message.content {
                    completion(.success(text))
                } else {
                    let e = URLError(.cannotParseResponse)
                    print("[DeepSeekManager] No content in response")
                    completion(.failure(e))
                }
            } catch {
                print("[DeepSeekManager] Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

private struct DeepSeekRequest: Codable {
    let model: String
    let messages: [DSMessage]
    let temperature: Double
    let max_tokens: Int?
    let stream: Bool?

    init(model: String,
         messages: [DSMessage],
         temperature: Double,
         max_tokens: Int? = nil,
         stream: Bool? = false)
    {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.stream = stream
    }
}

private struct DeepSeekResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]?
    let usage: Usage?

    struct Choice: Codable {
        let index: Int?
        let message: DSMessage
        let finish_reason: String?
    }

    struct Usage: Codable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }
}

private struct DSMessage: Codable {
    let role: String
    let content: String
}
