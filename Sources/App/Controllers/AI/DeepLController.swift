//
//  File.swift
//  
//
//  Created by Alon Yakoby on 22.02.24.
//

import Foundation
import Vapor

var globalDeepLkey: String?

/// A controller for handling DeepL translation related routes.
final class DeepLController: RouteCollection {
    
    // MARK: - Properties
    
    /// DeepL API authorization key.
    let authKey: String
    
    init(authKey: String) {
        self.authKey = authKey
    }
    
    /// Sets up routes for the application.
    /// - Parameter app: The application's `RoutesBuilder` to which routes will be added.
    func setupRoutes(on app: RoutesBuilder) throws {
        
        app.post("format", use: formatText)

        let route = app.grouped("translations")
        route.get(use: supportedLanguages)
        
        // Add route for translate
        route.post("translate", use: translate)
        route.post("verify", use: verifyTranslation)
    }

    // MARK: - Route Setup

    /// Required by `RouteCollection`. Calls `setupRoutes`.
    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
    
    // MARK: - API Methods
    
    /// Fetches supported languages from DeepL API.
    /// - Parameter req: The request object.
    /// - Returns: A future array of `DeepLSupportedLanguage`.
    func supportedLanguages(req: Request) -> EventLoopFuture<[DeepLSupportedLanguage]> {
        let promise = req.eventLoop.makePromise(of: [DeepLSupportedLanguage].self)
        
        guard let url = URL(string: "https://api-free.deepl.com/v2/languages?type=target") else {
            // Handle URL error
            return promise.futureResult
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(authKey, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                // Handle networking error
                promise.fail(error ?? Abort(.internalServerError))
                return
            }
            
            do {
                let languages = try JSONDecoder().decode([DeepLSupportedLanguage].self, from: data)
                promise.succeed(languages)
            } catch {
                // Handle JSON decoding error
                promise.fail(error)
            }
        }
        
        task.resume()
        return promise.futureResult
    }
    
    /// Translates text using the DeepL API.
    /// - Parameter req: The request object.
    /// - Returns: A future array of strings of the translated texts.
    func translate(req: Request) -> EventLoopFuture<[String]> {
        let promise = req.eventLoop.makePromise(of: [String].self)
        
        // Debugging: Print the request for debugging purposes
        debugPrint("Request received for translation: \(req)")
        debugPrint("Request received for body: \(req.body)")

        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            promise.fail(Abort(.badRequest, reason: "Invalid URL"))
            return promise.futureResult
        }
        
        do {
            // MARK: ERROR
            guard let reqData = req.body.data else { throw Abort(.badRequest)}
            var translateRequest = try JSONDecoder().decode(TranslateRequest.self, from: reqData)
            translateRequest.text = translateRequest.text.compactMap { return $0.formattedText(with: global_exceptions)}
            let requestBody = try JSONEncoder().encode(translateRequest)

            print(translateRequest)

            // Debugging: Print the request body for debugging purposes
            debugPrint("Translate Request: \(translateRequest)")
            debugPrint("Request Body: \(requestBody)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(authKey, forHTTPHeaderField: "Authorization")
            request.addValue("api-free.deepl.com", forHTTPHeaderField: "Host")
            request.httpBody = requestBody
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Debugging: Print response for debugging
                if let httpResponse = response as? HTTPURLResponse {
                    self.debugPrint("HTTP Status Code: \(httpResponse.statusCode)")
                }
                
                guard let data = data, error == nil else {
                    promise.fail(error ?? Abort(.internalServerError))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
                    let translations = response.translations?.map { $0.text } ?? []
                    if translations.isEmpty {
                        promise.fail(Abort(.internalServerError, reason: "No translations found"))
                    } else {
                        print("Translated from \(translateRequest.text.first) --> \(translations.first)")
                        promise.succeed(translations)
                    }
                } catch {
                    promise.fail(error)
                }
            }
            task.resume()
        } catch {
            // Log the error to see what went wrong
            print("Error decoding TranslateRequest: \(error)")
            promise.fail(error)
        }
        
        return promise.futureResult
    }

    func verifyTranslation(req: Request) -> EventLoopFuture<TranslationVerificationResponse> {
        // Create a new promise
        let promise = req.eventLoop.makePromise(of: TranslationVerificationResponse.self)
        
        do {
            guard let verificationRequestData = req.body.data else { throw Abort(.badRequest)}
            let verificationRequest = try JSONDecoder().decode(TranslationVerificationRequest.self, from: verificationRequestData)
            print("Request: ", verificationRequest)

            let manager = OllamaManager()
//            let manager = OpenAIManager()
            let prompt = """
            I have translated this string:
            \(verificationRequest.source)

            To this (in \(verificationRequest.target_language)):
            \(verificationRequest.translated)

            Please review the translations and check their correctness.

            If you find the translation to be accurate and do not have any suggestions for improvement, please indicate this by responding with "The translation is accurate." and provide a rating from 1 to 10, where 10 is the highest level of accuracy.

            Example response for accurate translations:
            "The translation is accurate."
            Rating: X (where X is a number from 1 to 10 indicating the accuracy of the translation)

            If you identify any inaccuracies or have suggestions for improving the translation, please provide the corrected version or your suggestions along with a rating from 1 to 10, where 10 represents a perfect translation and 1 indicates significant inaccuracies.

            Example response for translations needing improvement:
            "Suggested correction: [your suggested correction here]"
            Rating: Y (where Y is a number from 1 to 10 based on the suggested improvement's accuracy)

            """

            print(prompt)
            
            manager.basicPrompt(prompt: prompt, model: .mistral) { result in
                switch result {
                case .success(let response):
                    print("Response: ", response)
                    if let rating = response.extractRating() {
                        // Create a successful TranslationVerificationResponse with the extracted rating
                        let verificationResponse = TranslationVerificationResponse(feedback: response, rating: rating)
                        // Fulfill the promise with the verification response
                        promise.succeed(verificationResponse)
                    } else {
                        // Fail the promise if the rating couldn't be extracted
                        let error = NSError(domain: "TranslationVerificationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to extract rating from the response."])
                        promise.fail(error)
                    }
                case .failure(let error):
                    // Fail the promise with the encountered error
                    promise.fail(error)
                }
            }
        } catch {
            // Fail the promise if there was an error decoding the verification request
            promise.fail(error)
        }
        
        // Return the future from the promise
        return promise.futureResult
    }

    /// Formats text based on predefined rules.
    /// - Parameter req: The request object.
    /// - Returns: A future string of the formatted text.
    func formatText(req: Request) -> EventLoopFuture<String> {
        do {
            let formatRequest = try req.content.decode(FormatTextRequest.self)
            let text = formatRequest.text
            
            // Use the formattedText method from the String extension
            let formattedText = text.formattedText(with: global_exceptions)
            
            // Return the formatted text wrapped in a future
            return req.eventLoop.future(formattedText)
        } catch {
            // Handle errors
            return req.eventLoop.future(error: error)
        }
    }

    /// Prints a debug message to the console.
    /// - Parameter message: The message to be printed.
    func debugPrint(_ message: Any) {
        #if DEBUG
        print(message)
        #endif
    }
}

struct DeepLSupportedLanguage: Codable, Content {
    var name: String
    var language: String
    var supports_formality: Bool // Assuming this should be a Bool based on the naming
}

struct FormatTextRequest: Codable {
    var text: String
}

struct TranslateRequest: Codable {
    var source_lang: String
    var target_lang: String
    var context: String?
    var text: [String]
    let preserve_formatting = true
}

struct TranslateResponse: Codable {
    var translated: String
}
 
struct DeepLTranslateResponse: Codable {
    var translations: [Translation]?

    struct Translation: Codable {
        var detected_source_language: String?
        var text: String
    }
}

struct TranslationVerificationRequest: Codable {
    let source: String
    let translated: [String]
    let target_language: String

    enum CodingKeys: String, CodingKey {
        case source
        case translated
        case target_language = "target_language" // Explicitly mapping, though unnecessary in this case
    }
}

struct TranslationVerificationResponse: Codable, Content {
    let feedback: String
    let rating: Int
}

extension String {
    func formattedText(with exceptions: [[String: String]]) -> String {
        let sortedExceptions = exceptions.sorted { $0["replace"]!.count > $1["replace"]!.count }
        var formattedText = self

        for exception in sortedExceptions {
            if let replace = exception["replace"], let with = exception["with"] {
                var newText = ""
                var lastIndex = formattedText.startIndex // Adjusted to use formattedText's startIndex

                while let range = formattedText.range(of: "\\b\(replace)\\b", options: .regularExpression, range: lastIndex..<formattedText.endIndex) {
                    // Append the text up to the found word, followed by the replacement
                    newText += String(formattedText[lastIndex..<range.lowerBound]) + with
                    // Update lastIndex to skip over the replaced text
                    lastIndex = range.upperBound
                }

                // Append any remaining text after the last replacement
                newText += String(formattedText[lastIndex..<formattedText.endIndex])

                // If replacements were made, update formattedText with the newText for the next iteration
                if !newText.isEmpty {
                    formattedText = newText
                }
            }
        }

//        print("Formatted from \(self) --> \(formattedText)")
        return formattedText
    }
    
    func extractRating() -> Int? {
        let pattern = "Rating:\\s*(\\d+)/10"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: self, range: NSRange(location: 0, length: self.utf16.count)),
              let range = Range(match.range(at: 1), in: self),
              let rating = Int(self[range])
        else {
            return nil
        }
        return rating
    }

}

var global_exceptions: [[String: String]] =
    [
        ["replace": "W/", "with": "WITH"],
        // MATERIALS
        ["replace": "ALUMINIU", "with": "ALUMINIUM"],
        ["replace": "ALU", "with": "ALUMINIUM"],
        ["replace": "AL", "with": "ALUMINIUM"],
        ["replace": "FORG", "with": "FORGED"],
        ["replace": "PRESS", "with": "PRESSED"],
        ["replace": "CER", "with": "CERAMIC"],
        ["replace": "PORC", "with": "PORCELAIN"],
        ["replace": "MARB", "with": "MARBLE"],
        // BG WORDS
        ["replace": "Y/O", "with": "YEARS OLD"],
        ["replace": "S/S", "with": "STAINLESSSTEEL"],
        ["replace": "SS", "with": "STAINLESSSTEEL"],
        ["replace": "IND", "with": "INDUCTION"],
        // Brands
        ["replace": "LM", "with": "LA MAISON"],
        ["replace": "BG", "with": "BERGNER"],
        ["replace": "MP", "with": "MASTERPRO"],
        ["replace": "WB", "with": "WELLBERG"],
        ["replace": "RB", "with": "RENNBERG"],
        ["replace": "BE", "with": "BENNETON"],
        ["replace": "SH", "with": "SWISSHOUSE"],
        ["replace": "BF", "with": "BRUNCHFIELD"],
]
