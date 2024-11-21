import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class OllamaManager {
    let baseURL = "http://localhost:11434/"
    var generatePath: String { baseURL + "api/generate" }

    enum AIModel: String {
        case mistral = "mistral:latest"
        case llama3 = "llama3"
    }

    func basicPrompt(prompt: String, model: AIModel, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: generatePath) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let ollamaRequest = OllamaRequest(model: model.rawValue, prompt: prompt)

        do {
            request.httpBody = try JSONEncoder().encode(ollamaRequest)
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? URLError(.cannotLoadFromNetwork)))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let ollamaResponse = try decoder.decode(OllamaResponse.self, from: data)
                completion(.success(ollamaResponse.response))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool = false
}

struct OllamaResponse: Codable {
    let model: String
    let createdAt: String
    let response: String
    let done: Bool

    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
    }
}



class OpenAIManager {
    let baseURL = "https://api.openai.com/"
    var generatePath: String { baseURL + "v1/chat/completions" }

    let openAPIKey: String

    init(apiKey: String) {
        self.openAPIKey = apiKey
    }

    func basicPrompt(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: generatePath) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAPIKey)", forHTTPHeaderField: "Authorization")

        let requestBody = OpenAIRequest(
            model: "gpt-4",
            messages: [Message(role: "user", content: prompt)],
            temperature: 0.7
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? URLError(.cannotLoadFromNetwork)))
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
}

struct Message: Codable {
    let role: String
    let content: String
}
