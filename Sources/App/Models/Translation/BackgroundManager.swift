import Vapor
import Fluent

/// Manages background tasks related to translations.
final class BackgroundManager {
    private let eventLoop: EventLoop
    private let db: Database
    private let authKey: String
    var exceptions: [[String : String]] = []
    private var currentPage = 0 // Variable to keep track of the current page

    /// Initializes a new instance of BackgroundManager.
    /// - Parameters:
    ///   - eventLoop: The event loop to use for asynchronous operations.
    ///   - db: The database connection to use.
    ///   - authKey: The authorization key for API access.
    init(eventLoop: EventLoop, db: Database, authKey: String) {
        self.eventLoop = eventLoop
        self.db = db
        self.authKey = authKey
        
        Exception.query(on: db)
            .all()
            .map { exceptions in
                var exceptionDicts = exceptions.map { ["replace": $0.original, "with": $0.replace.uppercased()] }
                global_exceptions = exceptionDicts
                self.exceptions = exceptionDicts
                print("Loaded exceptions: \(self.exceptions)") // Debugging statement
            }
            .whenComplete { _ in
                self.startWatching()
            }
    }

    /// Starts the watcher as a scheduled task.
    private func startWatching() {
        self.eventLoop.scheduleRepeatedAsyncTask(initialDelay: .seconds(0), delay: .seconds(5)) { task in
            self.watchPendingTranslations().map {
                // If there are no more pages to process, cancel the task
                if self.currentPage == 0 {
                    task.cancel()
                }
            }.flatMapError { error in
                print("Error in repeated task: \(error)")
                return self.eventLoop.makeSucceededFuture(())
            }
        }
    }

    /// Watches pending translations and processes them.
    private func watchPendingTranslations() -> EventLoopFuture<Void> {
        print("Starting watchPendingTranslations...")
        return Translation.query(on: db)
            .filter(\.$status == .pending)
            .range(lower: currentPage * 10, upper: (currentPage + 1) * 10)
            .all()
            .flatMap { pendingTranslations in
                
                print("Found \(pendingTranslations.count) pending translations on page \(self.currentPage).")
                
                if pendingTranslations.isEmpty {
                    // No more translations to process, reset currentPage
                    self.currentPage = 0
                    return self.eventLoop.makeSucceededFuture(())
                }

                let processFutures = pendingTranslations.map { translation in
                    self.processTranslation(translation)
                }
                
                self.currentPage += 1 // Increment the page index for the next batch
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
            translation.status = .formatted
            // Save the updated translation
            return translation.save(on: self.db).map {
                return formattedText
            }
        }
    }

    /// Translates text using the DeepL API.
    /// - Parameters:
    ///   - translation: The translation object to update.
    ///   - sourceLang: The source language code.
    ///   - targetLang: The target language code.
    /// - Returns: A future that resolves to the updated translation object.
    func translate(_ translation: Translation, from sourceLang: String, to targetLang: String) -> EventLoopFuture<Translation> {
        print("Translating text: \(translation.base) from \(sourceLang) to \(targetLang)")
        let promise = db.eventLoop.makePromise(of: Translation.self)
        
        guard let url = URL(string: "https://api-free.deepl.com/v2/translate") else {
            promise.fail(Abort(.badRequest, reason: "Invalid URL"))
            return promise.futureResult
        }

        let translateRequest = TranslateRequest(source_lang: sourceLang, target_lang: targetLang, context: nil, text: [translation.base])
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
                        print("Translated text in Translate Function: \(translations)")
                        translation.status = .translated
                        translation.translation = translations.joined(separator: " ")
                        translation.save(on: self.db).whenComplete { result in
                            switch result {
                            case .success:
                                promise.succeed(translation)
                            case .failure(let error):
                                promise.fail(error)
                            }
                        }
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
    /// - Returns: A future that resolves to a TranslationVerificationResponse.
    func verifyTranslation(_ source: String, _ translated: [String], _ targetLanguage: String) -> EventLoopFuture<TranslationVerificationResponse> {
        print("Verifying translation from: \(source) to \(translated) in \(targetLanguage)")
        let promise = db.eventLoop.makePromise(of: TranslationVerificationResponse.self)
        
        let prompt = """
        I have translated this string:
        \(source)

        To this (in \(targetLanguage)):
        \(translated.joined(separator: " "))

        Please review the translations and check their correctness.

        Your response should be formatted as follows:

        Original: \(source)
        Translation: \(translated.joined(separator: " "))

        Context: [if there is a comment you want to make, it can be blank]

        Rating: X/10 [where X is a number from 1 to 10 indicating the accuracy of the translation]

        Example response for accurate translations:
        Original: The quick brown fox jumps over the lazy dog.
        Translation: Der schnelle braune Fuchs springt über den faulen Hund.

        Context:

        Rating: 10/10

        Example response for translations needing improvement:
        Original: The quick brown fox jumps over the lazy dog.
        Translation: Der schnelle braune Fuchs springt über den faulen Hund.

        Context: The translation is mostly accurate, but the word "lazy" could also be translated as "träge".

        Rating: 9/10
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
        print("Processing translation for item: \(translation.itemCode)")
        
        return self.translate(translation, from: "EN", to: translation.language.rawValue).flatMap { updatedTranslation in
            print("Translated text in Processing Function: \(updatedTranslation.translation ?? "")")
            
            // VERIFICATION
            let verified = self.verifyTranslation(updatedTranslation.base, [updatedTranslation.translation ?? ""], updatedTranslation.language.rawValue)
            return verified.flatMap { verificationResponse in
                if verificationResponse.rating > 3 {
                    updatedTranslation.verification = verificationResponse.feedback
                    updatedTranslation.rating = verificationResponse.rating
                    updatedTranslation.status = .completed
                    print("Translation completed for item: \(updatedTranslation.itemCode)")
                } else {
                    updatedTranslation.status = .failed
                    print("Translation failed for item: \(updatedTranslation.itemCode)")
                }
                return updatedTranslation.save(on: self.db).map {
                    print("Saved translation for item: \(updatedTranslation.itemCode)")
                }.flatMapError { error in
                    print("Error saving translation: \(error)")
                    return self.db.eventLoop.makeFailedFuture(error)
                }
            }
        }.flatMapError { error in
            print("Error translating text: \(error)")
            return self.db.eventLoop.makeFailedFuture(error)
        }
    }
}
