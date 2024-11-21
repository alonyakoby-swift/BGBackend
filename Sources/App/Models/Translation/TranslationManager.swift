
import Vapor
import Foundation
import Fluent

protocol TranslationManagerProtocol {
    var db: Database { get }
    var authKey: String { get }
    
    func formatText(productID: UUID) async throws
    func translateText(translationID: UUID, toLanguage: Language, productID: UUID) async throws
    func verifyText(translationID: UUID) async throws
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
    
    func formatText(productID: UUID) async throws {
        // Fetch all exceptions
        let exceptions = try await Exception.query(on: db).all()
        // Convert exceptions into a single dictionary
        let exceptionDict = exceptions.reduce(into: [String: String]()) { dict, exception in
            dict.merge(exception.asDictionary()) { (_, new) in new }
        }
        
        // Fetch the product by ID
        guard let product = try await Product.find(productID, on: db) else {
            throw Abort(.notFound)
        }
        
        // Format the product description using the exceptions
        product.ProductDescriptionEN = product.ProductDescriptionEN?.formattedText(with: [exceptionDict])
        
        // Save the updated product
        try await product.save(on: db)
    }
    
    func translateText(translationID: UUID, toLanguage: Language, productID: UUID) async throws {
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            throw Abort(.badRequest, reason: "Invalid URL")
        }

        // Fetch all exceptions (if any)
        let exceptions = try await Exception.query(on: db).all()
        let exceptionDict = exceptions.reduce(into: [String: String]()) { dict, exception in
            dict.merge(exception.asDictionary()) { (_, new) in new }
        }

        // Fetch the existing translation by ID
        guard let translationDB = try await Translation.find(translationID, on: db) else {
            throw Abort(.notFound, reason: "Translation not found")
        }

        // Format the base text with exceptions
        let description = translationDB.base.formattedText(with: [exceptionDict])

        // Prepare the form data for DeepL API
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = [
            URLQueryItem(name: "text", value: description),
            URLQueryItem(name: "target_lang", value: toLanguage.code),
            URLQueryItem(name: "source_lang", value: "EN")
        ]

        guard let bodyString = requestBodyComponents.percentEncodedQuery,
              let bodyData = bodyString.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Failed to encode request body")
        }

        // Debugging: Print the request body
        print("Request Body String: \(bodyString)")

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        // Set the Authorization header
        request.addValue(authKey, forHTTPHeaderField: "Authorization")

        // Debugging: Print the full request
        print("Request URL: \(request.url?.absoluteString ?? "No URL")")
        print("Request Method: \(request.httpMethod ?? "No Method")")
        print("Authorization Header: \(authKey)")
        print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Request Body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "No Body")")

        // Perform the request using async/await
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check the response status code
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    throw Abort(.internalServerError, reason: "DeepL API error: \(errorMessage)")
                } else {
                    throw Abort(.internalServerError, reason: "DeepL API error: Unknown error")
                }
            }

            // Debugging: Print the response data as string
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            } else {
                print("Failed to decode response data as UTF-8 string")
            }

            // Decode the response
            let deeplResponse = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
            guard let translations = deeplResponse.translations, !translations.isEmpty else {
                throw Abort(.internalServerError, reason: "No translations received from DeepL API")
            }

            // Update the existing translation
            translationDB.translation = translations.first?.text ?? "Error Translating"
            translationDB.status = .translated
            translationDB.language = toLanguage

            // Save the updated translation
            try await translationDB.save(on: self.db)

        } catch {
            // Handle any errors
            print("Error performing translation request: \(error)")
            throw error
        }
    }


    // Helper function to mask the API key in logs
    private func maskAPIKey(_ authHeader: String) -> String {
        // Assuming authHeader is "DeepL-Auth-Key YOUR_API_KEY"
        let components = authHeader.split(separator: " ")
        guard components.count == 2 else { return authHeader }
        let apiKey = String(components[1])
        let maskedKey = String(apiKey.prefix(5)) + "..." + String(apiKey.suffix(5))
        return "\(components[0]) \(maskedKey)"
    }



    
    func verifyText(translationID: UUID) async throws {
        // Fetch the existing translation by ID and eager load the product relation
        guard let translationDB = try await Translation.query(on: db)
            .with(\.$product) // Eager-load the product relation
            .filter(\.$id == translationID)
            .first() else {
            throw Abort(.notFound, reason: "Translation not found")
        }

        // Ensure translation text exists
        guard !translationDB.translation.isEmpty else {
            throw Abort(.badRequest, reason: "No translation text available for verification")
        }

        let translatedText = translationDB.translation

        // Ensure the product is loaded
        guard let product = translationDB.$product.value else {
            throw Abort(.internalServerError, reason: "Product relation not loaded")
        }

        // Prepare the prompt text
        let promptText = product.promptText(language: translationDB.language, translatedText: translatedText)

        print("Prompt Text: \(promptText)") // Debugging output

        // Use AIManager to verify the text
        let verificationResult: String
        do {
            verificationResult = try await withCheckedThrowingContinuation { continuation in
                aiManager.basicPrompt(prompt: promptText) { result in
                    switch result {
                    case .success(let response):
                        print("AI Verification Success: \(response)") // Debugging output
                        continuation.resume(returning: response)
                    case .failure(let error):
                        print("AI Verification Failure: \(error.localizedDescription)") // Debugging output
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            throw Abort(.internalServerError, reason: "Failed to verify translation: \(error.localizedDescription)")
        }

        // Parse feedback and rating from the AI response
        let feedbackParser = FeedbackParser(response: verificationResult)
        let feedback = feedbackParser.parseFeedback()
        let rating = feedbackParser.parseRating()

        print("Feedback: \(feedback), Rating: \(rating ?? 0)") // Debugging output

        // Update the translation entity
        translationDB.verification = feedback
        translationDB.rating = rating ?? 0
        translationDB.status = .completed

        // Save changes to the database
        try await translationDB.save(on: db)
    }
}
