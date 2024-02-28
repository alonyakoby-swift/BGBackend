import Foundation

class OllamaManager {
    
    let baseURL = "http://localhost:11434/"
    var generatePath: String { baseURL + "api/generate" }
    
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
            let requestBody = try JSONEncoder().encode(ollamaRequest)
            request.httpBody = requestBody
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
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
    
    enum AIModel: String {
        case mistral = "mistral:latest"
    }
}

struct OllamaRequest: Codable {
    var model: String
    var prompt: String
    var stream: Bool = false
    
    init(model: String, prompt: String) {
        self.model = model
        self.prompt = prompt
    }
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


import Foundation

class OpenAIManager {
    
    let baseURL = "https://api.openai.com/"
    var generatePath: String { baseURL + "v1/chat/completions" }
    
    let openAPIKey = "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" // Replace with your actual API key
    
    func basicPrompt(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: generatePath) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(openAPIKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = OPENAIRequest(
            model: "gpt-4-turbo-preview",
//            model: "gpt-3.5-turbo-1106",
            messages: [Message(role: "user", content: prompt)],
            temperature: 0.7
        )
        
        do {
            let requestData = try JSONEncoder().encode(requestBody)
            request.httpBody = requestData
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
                // Directly parsing the response to extract the content
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

struct OPENAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
}

struct Message: Codable {
    let role: String
    let content: String
}
