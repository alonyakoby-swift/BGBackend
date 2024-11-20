import Foundation

class AIManager {
    let ollama: OllamaManager
    let openAI: OpenAIManager
    let model: AIModel

    enum AIModel: String {
        case llama3 = "llama3"
        case openAI = "openAI"
        case mistral = "mistral:latest"

        var description: String {
            switch self {
            case .llama3:
                return "Llama 3 - Meta's public model via Ollama Manager. Runs offline, no authentication required. Slower but loaded with custom Bergner Data."
            case .openAI:
                return "ChatGPT 4 - OpenAI's private model. Requires internet and subscription. Fast, optimized for grammar and translation."
            case .mistral:
                return "Mistral - Public model via Ollama Manager. Offline, no authentication required. Good for grammar/translation but slower. Includes custom Bergner Data."
            }
        }
    }

    init(ollama: OllamaManager, openAI: OpenAIManager, model: AIModel) {
        self.ollama = ollama
        self.openAI = openAI
        self.model = model
    }

    func basicPrompt(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        switch model {
        case .llama3, .mistral:
            if let ollamaModel = OllamaManager.AIModel(rawValue: model.rawValue) {
                ollama.basicPrompt(prompt: prompt, model: ollamaModel, completion: completion)
            } else {
                completion(.failure(NSError(domain: "Invalid Model", code: -1, userInfo: nil)))
            }
        case .openAI:
            openAI.basicPrompt(prompt: prompt, completion: completion)
        }
    }
}
