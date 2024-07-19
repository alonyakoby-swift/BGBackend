import Vapor
import Fluent
import Combine

/// Manages background tasks related to translations.
final class BackgroundManager {
    private var cancellables = Set<AnyCancellable>()
    private let eventLoop: EventLoop
    private let db: Database
    private let authKey: String
    private let semaphore = DispatchSemaphore(value: 8)

    /// Initializes a new instance of `BackgroundManager`.
    /// - Parameters:
    ///   - eventLoop: The event loop to use for asynchronous operations.
    ///   - db: The database connection to use.
    ///   - authKey: The authorization key for API access.
    init(eventLoop: EventLoop, db: Database, authKey: String) {
        self.eventLoop = eventLoop
        self.db = db
        self.authKey = authKey
        startWatching()
    }

    /// Starts the watcher as a scheduled task.
    private func startWatching() {
        self.eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(0), delay: .seconds(10)) { task in
            self.watchPendingTranslations()
                .flatMapError { error in
                    self.eventLoop.makeSucceededFuture(())
                }
        }
    }

    /// Watches pending translations and processes them.
    private func watchPendingTranslations() -> EventLoopFuture<Void> {
        print("Starting watchPendingTranslations...")
        return Translation.query(on: db).filter(\.$status == .pending).filter(\.$language == .de).all()
            .flatMap { pendingTranslations in
                print("Found \(pendingTranslations.count) pending translations.")
                let limitedTranslations = Array(pendingTranslations.prefix(8))
                let processFutures = limitedTranslations.map { translation in
                    self.processTranslation(translation)
                }
                return EventLoopFuture.andAllSucceed(processFutures, on: self.eventLoop)
            }
            .flatMapError { error in
                print("Error processing translations: \(error)")
                return self.eventLoop.makeSucceededFuture(())
            }
    }

    /// Formats text based on predefined rules.
    /// - Parameter translation: The translation to format.
    /// - Returns: A future that resolves to the formatted text.
    func formatText(_ translation: Translation) -> EventLoopFuture<String> {
        print("Formatting text: \(translation.base)")
        return Exception.query(on: db).all().flatMap { exceptions in
            let exceptionDicts = exceptions.map { ["replace": $0.original.debugDescription, "with": $0.replace.uppercased()] }
            let formattedText = translation.base.formattedText(with: exceptionDicts)
            print("Formatted text: \(formattedText)")

            // Update the base property of the translation
            translation.base = formattedText
            translation.status = .inprogress
            // Save the updated translation
            return translation.save(on: self.db).map {
                return formattedText
            }
        }
    }

    /// Translates text using the DeepL API.
    /// - Parameters:
    ///   - text: The text to translate.
    ///   - sourceLang: The source language code.
    ///   - targetLang: The target language code.
    /// - Returns: A future that resolves to an array of translated texts.
    func translate(_ text: String, from sourceLang: String, to targetLang: String) -> EventLoopFuture<[String]> {
        print("Translating text: \(text) from \(sourceLang) to \(targetLang)")
        let promise = db.eventLoop.makePromise(of: [String].self)
        
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            promise.fail(Abort(.badRequest, reason: "Invalid URL"))
            return promise.futureResult
        }

        let translateRequest = TranslateRequest(source_lang: sourceLang, target_lang: targetLang, context: nil, text: [text])
        do {
            let requestBody = try JSONEncoder().encode(translateRequest)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(self.authKey, forHTTPHeaderField: "Authorization")
            request.httpBody = requestBody
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                }
                
                guard let data = data, error == nil else {
                    print("Translation request error: \(String(describing: error))")
                    promise.fail(error ?? Abort(.internalServerError))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
                    let translations = response.translations?.map { $0.text } ?? []
                    if translations.isEmpty {
                        print("No translations found")
                        promise.fail(Abort(.internalServerError, reason: "No translations found"))
                    } else {
                        print("Translated text: \(translations)")
                        promise.succeed(translations)
                    }
                } catch {
                    print("Error decoding translation response: \(error)")
                    promise.fail(error)
                }
            }
            task.resume()
        } catch {
            print("Error encoding TranslateRequest: \(error)")
            promise.fail(error)
        }
        
        return promise.futureResult
    }

    /// Verifies the translation.
    /// - Parameters:
    ///   - source: The source text.
    ///   - translated: The translated texts.
    ///   - targetLanguage: The target language code.
    /// - Returns: A future that resolves to a `TranslationVerificationResponse`.

    func verifyTranslation(_ source: String, _ translated: [String], _ targetLanguage: String) -> EventLoopFuture<TranslationVerificationResponse> {
        print("Verifying translation from: \(source) to \(translated) in \(targetLanguage)")
        let promise = db.eventLoop.makePromise(of: TranslationVerificationResponse.self)
        
        let prompt = """
        I have translated this string:
        \(source)

        To this (in \(targetLanguage)):
        \(translated.joined(separator: " "))

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

        let manager = OllamaManager()
        manager.basicPrompt(prompt: prompt, model: .mistral) { result in
            switch result {
            case .success(let response):
                print("Verification response: \(response)")
                if let rating = response.extractRating() {
                    let verificationResponse = TranslationVerificationResponse(feedback: response, rating: rating)
                    promise.succeed(verificationResponse)
                } else {
                    let error = NSError(domain: "TranslationVerificationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to extract rating from the response."])
                    print("Failed to extract rating")
                    promise.fail(error)
                }
            case .failure(let error):
                print("Verification error: \(error)")
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }

    /// Processes each translation.
    /// - Parameter translation: The translation to process.
    /// - Returns: A future that resolves when the translation is processed.
    private func processTranslation(_ translation: Translation) -> EventLoopFuture<Void> {
        semaphore.wait()
        print("Processing translation for item: \(translation.itemCode)")
        
        return Exception.query(on: db).all().flatMap { exceptions in
            let exceptionDicts = exceptions.map { ["replace": $0.original, "with": $0.replace] }
            let formattedText = translation.base.formattedText(with: exceptionDicts)
            
            return self.translate(formattedText, from: "EN", to: translation.language.rawValue).flatMap { translatedTexts in
                let verified = self.verifyTranslation(translation.base, translatedTexts, translation.language.rawValue)
                
                return verified.flatMap { verificationResponse in
                    if verificationResponse.rating > 7 {
                        translation.translation = translatedTexts.joined(separator: " ")
                        translation.status = .completed
                        print("Translation completed for item: \(translation.itemCode)")
                    } else {
                        translation.status = .failed
                        print("Translation failed for item: \(translation.itemCode)")
                    }
                    return translation.save(on: self.db).map {
                        self.semaphore.signal()
                    }.flatMapError { error in
                        self.semaphore.signal()
                        return self.db.eventLoop.makeFailedFuture(error)
                    }
                }
            }
        }
    }
}
