//
//  File.swift
//  
//
//  Created by Alon Yakoby on 22.02.24.
//

import Foundation
import Vapor

/// A controller for handling DeepL translation related routes.
final class DeepLController: RouteCollection {
    
    /// DeepL API authorization key
    let authKey = "DeepL-Auth-Key 054c8386-bc46-48af-a919-1d79960b400f:fx"
    
    /// Sets up routes for the application.
    /// - Parameter app: The application's `RoutesBuilder` to which routes will be added.
    func setupRoutes(on app: RoutesBuilder) throws {
        app.post("format", use: formatText)

        let route = app.grouped("translations")
        route.get(use: supportedLanguages)
        
        // Add route for translate
        route.post("translate", use: translate)
    }

    /// Required by `RouteCollection`. Calls `setupRoutes`.
    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
    
    
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
    /// - Returns: A future string of the translated text.
    func translate(req: Request) -> EventLoopFuture<String> {
        let promise = req.eventLoop.makePromise(of: String.self)
        
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
            let translateRequest = try JSONDecoder().decode(TranslateRequest.self, from: reqData)
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
            request.addValue("api-free.deepl.com", forHTTPHeaderField: "Origin")
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
                    if let firstTranslation = response.translations?.first {
                        promise.succeed(firstTranslation.text)
                    } else {
                        promise.fail(Abort(.internalServerError, reason: "No translations found"))
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

    
    /// Formats text based on predefined rules.
    /// - Parameter req: The request object.
    /// - Returns: A future string of the formatted text.
    func formatText(req: Request) -> EventLoopFuture<String> {
        do {
            let formatRequest = try req.content.decode(FormatTextRequest.self)
            var text = formatRequest.text
            
            // Sort exceptions by 'replace' string length in descending order
            let sortedExceptions = exceptions.sorted { $0["replace"]!.count > $1["replace"]!.count }
            
            for exception in sortedExceptions {
                if let replace = exception["replace"], let with = exception["with"] {
                    var newText = ""
                    var lastIndex = text.startIndex // Keep track of the last index we've processed
                    
                    // Use a while loop to repeatedly search for occurrences of the replace string
                    while let range = text.range(of: "\\b\(replace)\\b", options: .regularExpression, range: lastIndex..<text.endIndex) {
                        // Append the text up to the found word, followed by the replacement
                        newText += String(text[lastIndex..<range.lowerBound]) + with
                        // Update lastIndex to skip over the replaced text
                        lastIndex = range.upperBound
                    }
                    
                    // Append any remaining text after the last replacement
                    newText += String(text[lastIndex..<text.endIndex])
                    
                    // Update text with the newText for the next iteration
                    text = newText
                }
            }

            // Return the formatted text wrapped in a future
            return req.eventLoop.future(text)
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

let exceptions: [[String: String]] = [
    // COMMON
    ["replace": "W/", "with": "WITH"],
    // MATERIALS
    ["replace": "ALUMINIU", "with": "ALUMINIUM"],
    ["replace": "ALU", "with": "ALUMINIUM"],
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
    ["replace": "MP", "with": "MASTER PRO"],
    ["replace": "WB", "with": "WELLBERG"],
    ["replace": "RB", "with": "RENNBERG"],
    ["replace": "BE", "with": "BENNETON"],
    ["replace": "SH", "with": "SWISS HOUSE"],
    ["replace": "BF", "with": "BRUNCHFIELD"],
]
