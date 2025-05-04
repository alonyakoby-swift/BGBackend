import Vapor
import Fluent
import Foundation

#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineFoundation
#endif
class DeepSeekManager {
    let baseURL = "https://api.deepseek.com/"
    var generatePath: String { baseURL + "v1/chat/completions" }
    
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateResponse(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: generatePath) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = DeepSeekRequest(
            model: "deepseek-chat",
            messages: [DSMessage(role: "user", content: prompt)],
            temperature: 0.7,
            max_tokens: 2048
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("[ERROR] Failed to encode DeepSeek request body: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[ERROR] URLSession error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                print("[ERROR] No data or invalid response")
                completion(.failure(URLError(.cannotLoadFromNetwork)))
                return
            }
            
            print("[DEBUG] DeepSeek Status Code: \(httpResponse.statusCode)")
            print("[DEBUG] DeepSeek Raw Response: \(String(data: data, encoding: .utf8) ?? "Unreadable data")")
            
            guard httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "DeepSeekAPI", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "DeepSeek API Error: \(String(data: data, encoding: .utf8) ?? "Unknown error")"
                ])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(DeepSeekResponse.self, from: data)
                
                if let content = response.choices?.first?.message.content {
                    completion(.success(content))
                } else {
                    print("[ERROR] DeepSeek response parsing failed: No content found")
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                print("[ERROR] JSON Decoding Failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

struct DeepSeekRequest: Codable {
    let model: String
    let messages: [DSMessage]
    let temperature: Double
    let max_tokens: Int?
    let stream: Bool?
    
    init(model: String, messages: [DSMessage], temperature: Double, max_tokens: Int? = nil, stream: Bool? = false) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.stream = stream
    }
}

struct DeepSeekResponse: Codable {
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

struct DSMessage: Codable {
    let role: String
    let content: String
}
