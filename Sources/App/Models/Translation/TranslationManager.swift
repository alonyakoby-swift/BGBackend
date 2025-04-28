import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Vapor
import Fluent

protocol TranslationManagerProtocol {
    var db: Database { get }
    var authKey: String { get }

    func processProductWorkflow(productID: UUID) async throws
    func formatProductDescription(productID: UUID) async throws
    func format(text: String, exceptions: [String: String]?) async -> String
    func translateProductText(translationID: UUID, toLanguage: Language) async throws
    func translate(text: String, from sourceLang: Language, to targetLang: Language) async throws -> String
    func batchTranslate(texts: [String], from sourceLang: Language, to targetLang: Language) async throws -> [String]
    func verifyProductTranslation(translationID: UUID) async throws
    func verifyTranslation(product: Product, translatedText: String, language: Language) async throws -> (feedback: String, rating: Int)
    func fetchExceptions() async throws -> [String: String]
    func maskAPIKey(_ authHeader: String) -> String
}

final class TranslationManager: TranslationManagerProtocol {
    var db: Database
    var authKey: String
    var aiManager: AIManager

    init(db: Database, authKey: String, aiManager: AIManager) {
        self.db = db
        self.authKey = authKey
        self.aiManager = aiManager
    }

    func processProductWorkflow(productID: UUID) async throws {
        print("[DEBUG] Starting processProductWorkflow for productID: \(productID)")
        try await formatProductDescription(productID: productID)

        let translations = try await Translation.query(on: db)
            .filter(\.$product.$id == productID)
            .all()

        let batches = translations.chunked(into: 3)

        for batch in batches {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for translation in batch where !translation.language.isEnglish {
                    group.addTask {
                        print("[DEBUG] Translating for language: \(translation.language)")
                        try await self.translateProductText(translationID: try translation.requireID(), toLanguage: translation.language)
                    }
                }
                try await group.waitForAll()
            }
        }

        Task.detached {
            await self.runVerificationInBackground(for: productID)
        }
    }

    func runVerificationInBackground(for productID: UUID) async {
        do {
            let translations = try await Translation.query(on: db)
                .filter(\.$product.$id == productID)
                .filter(\.$status == .translated)
                .all()

            let batches = translations.chunked(into: 10)

            for batch in batches {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for translation in batch {
                        group.addTask {
                            try await self.verifyProductTranslation(translationID: try translation.requireID())
                        }
                    }
                    try await group.waitForAll()
                }
            }
            print("[DEBUG] Background verification completed for productID: \(productID)")
        } catch {
            print("[ERROR] Verification background task failed: \(error.localizedDescription)")
        }
    }

    func formatProductDescription(productID: UUID) async throws {
        print("[DEBUG] Formatting product description for productID: \(productID)")
        let exceptions = try await fetchExceptions()
        guard let product = try await Product.find(productID, on: db) else {
            print("[ERROR] Product not found for ID: \(productID)")
            throw Abort(.notFound)
        }
        product.description = await format(text: product.description, exceptions: exceptions)
        try await product.save(on: db)
        print("[DEBUG] Product description formatted and saved for productID: \(productID)")
    }

    func format(text: String, exceptions: [String: String]? = nil) async -> String {
        print("[DEBUG] Formatting text")
        guard let exceptions = exceptions else { return text }
        return text.formattedText(with: [exceptions])
    }

    func translateProductText(translationID: UUID, toLanguage: Language) async throws {
        print("[DEBUG] Starting translateProductText for translationID: \(translationID)")
        let exceptions = try await fetchExceptions()
        guard let translationDB = try await Translation.find(translationID, on: db) else {
            print("[ERROR] Translation not found for ID: \(translationID)")
            throw Abort(.notFound)
        }
        let formattedBase = translationDB.base.formattedText(with: [exceptions])
        let translatedText = try await translate(text: formattedBase, from: .enUS, to: toLanguage)

        translationDB.translation = translatedText
        translationDB.status = .translated
        try await translationDB.save(on: db)
        print("[DEBUG] Translation completed and saved for translationID: \(translationID)")
    }

    func translate(text: String, from sourceLang: Language, to targetLang: Language) async throws -> String {
        print("[DEBUG] Translating text from \(sourceLang) to \(targetLang)")

        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "target_lang", value: targetLang.deeplCode),
            URLQueryItem(name: "source_lang", value: sourceLang.deeplCode)
        ]

        guard let bodyString = requestBodyComponents.percentEncodedQuery,
              let bodyData = bodyString.data(using: .utf8) else {
            print("[ERROR] Failed to encode request body")
            throw Abort(.internalServerError, reason: "Failed to encode request body")
        }

        var request = URLRequest(url: URL(string: "https://api-free.deepl.com/v2/translate")!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        request.addValue(authKey, forHTTPHeaderField: "Authorization")

        print("[DEBUG] Sending request to DeepL API")

        let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("[ERROR] URLSession error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    print("[ERROR] Unknown URLSession error")
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }.resume()
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[ERROR] DeepL API error: \(errorMessage)")
            throw Abort(.internalServerError, reason: "DeepL API error: \(errorMessage)")
        }

        print("[DEBUG] DeepL response received, attempting to decode")
        print("[DEBUG] Raw Response: \(String(data: data, encoding: .utf8) ?? "No readable data")")

        let deeplResponse = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
        return deeplResponse.translations?.first?.text ?? "Error Translating"
    }

    func batchTranslate(texts: [String], from sourceLang: Language, to targetLang: Language) async throws -> [String] {
        print("[DEBUG] Starting batchTranslate for \(texts.count) texts")
        return try await withThrowingTaskGroup(of: String.self) { group in
            for text in texts {
                group.addTask {
                    try await self.translate(text: text, from: sourceLang, to: targetLang)
                }
            }
            return try await group.reduce(into: [String]()) { $0.append($1) }
        }
    }

    func verifyProductTranslation(translationID: UUID) async throws {
        print("[DEBUG] Starting verifyProductTranslation for translationID: \(translationID)")
        guard let translationDB = try await Translation.query(on: db)
            .with(\.$product)
            .filter(\.$id == translationID)
            .first() else {
            print("[ERROR] Translation not found for ID: \(translationID)")
            throw Abort(.notFound)
        }

        let product = translationDB.product
        let (feedback, rating) = try await verifyTranslation(
            product: product,
            translatedText: translationDB.translation,
            language: translationDB.language
        )

        translationDB.verification = feedback
        translationDB.rating = rating
        translationDB.status = .completed
        try await translationDB.save(on: db)
        print("[DEBUG] Verification completed and saved for translationID: \(translationID)")
    }

    func verifyTranslation(product: Product, translatedText: String, language: Language) async throws -> (feedback: String, rating: Int) {
        print("[DEBUG] Starting verifyTranslation for productID: \(product.id?.uuidString ?? "nil")")
        let promptText = product.promptText(language: language, translatedText: translatedText)
        print("[DEBUG] Prompt: \(promptText)")
        let verificationResult = try await withCheckedThrowingContinuation { continuation in
            aiManager.basicPrompt(prompt: promptText) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    print("[ERROR] AIManager prompt failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }

        let parser = FeedbackParser(response: verificationResult)
        return (parser.parseFeedback(), parser.parseRating() ?? 0)
    }

    func fetchExceptions() async throws -> [String: String] {
        print("[DEBUG] Fetching exceptions")
        let exceptions = try await Exception.query(on: db).all()
        print("[DEBUG] Retrieved \(exceptions.count) exceptions")
        return exceptions.reduce(into: [String: String]()) { $0.merge($1.asDictionary()) { _, new in new } }
    }

    func maskAPIKey(_ authHeader: String) -> String {
        let components = authHeader.split(separator: " ")
        guard components.count == 2 else { return authHeader }
        let apiKey = components[1]
        return "\(components[0]) \(apiKey.prefix(5))...\(apiKey.suffix(5))"
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
