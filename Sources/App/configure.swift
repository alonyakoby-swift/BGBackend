//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Vapor
import Fluent
import FluentMongoDriver
import Leaf
import Queues
import QueuesMongoDriver
import MongoKitten
import DotEnv

extension String {
    var bytes: [UInt8] { .init(self.utf8) }
}

public func configure(_ app: Application) throws {
    // MARK: - Load Environment Variables
    let path = "\(app.directory.workingDirectory).env"
    do {
        try DotEnv.load(path: path)
    } catch {
        fatalError("Error loading .env file at path \(path): \(error)")
    }

    // MARK: - JSON Encoder/Decoder Configuration
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // MARK: - Server Configuration
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

    // MARK: - Database Configuration
    guard let databaseURL = Environment.get("DATABASE_URL") else {
        fatalError("DATABASE_URL not set in environment variables")
    }
    try app.databases.use(.mongo(connectionString: databaseURL), as: .mongo)

    // Apply migrations
    app_migrations.forEach { app.migrations.add($0) }
    try app.autoMigrate().wait()

    // MARK: - Leaf Configuration
    app.views.use(.leaf)

    // MARK: - Middleware Configuration
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.passwords.use(.bcrypt)

    // Configure allowed origins for CORS
    let allowedOrigins: [String] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:4000",
        "http://localhost:4001",
        "http://localhost:5500",
        "http://localhost:4500"
    ]

    // CORS Middleware
    let corsMiddleware = CustomCORSMiddleware(
        allowedOrigins: allowedOrigins,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [
            "Authorization",
            "Content-Type",
            "Accept",
            "Origin",
            "X-Requested-With",
            "User-Agent",
            "sec-ch-ua",
            "sec-ch-ua-mobile",
            "sec-ch-ua-platform"
        ],
        allowCredentials: true
    )

    app.middleware.use(corsMiddleware, at: .beginning)

    // MARK: - MongoKitten Configuration
    let mongoDatabase = try MongoDatabase.connect(databaseURL, on: app.eventLoopGroup.next()).wait()
    try app.queues.use(.mongodb(mongoDatabase))
    globalDB = app.db

    // MARK: - API Keys and AI Manager
    guard let deepLKey = Environment.get("DEEPL_API_KEY") else {
        fatalError("DEEPL_API_KEY not set in environment variables")
    }
    globalDeepLkey = deepLKey

    let ollama = OllamaManager()
    guard let openAIApiKey = Environment.get("OPENAI_API_KEY") else {
        fatalError("OPENAI_API_KEY not set in environment variables")
    }
    let openAI = OpenAIManager(apiKey: openAIApiKey)

    globalTranslationManager = TranslationManager(
        db: app.db,
        authKey: deepLKey,
        aiManager: AIManager(ollama: ollama, openAI: openAI, model: .openAI)
    )

    // Debugging keys
    app.logger.info("DEEP: \(deepLKey)")
    app.logger.info("OPENAI: \(openAIApiKey)")

    // MARK: - Scheduled Jobs
    app.queues.schedule(TestJob())
        .weekly()
        .on(.monday)
        .at(8, 0)

    // Start scheduled jobs
    try app.queues.startScheduledJobs()

    // MARK: - Routes
    try routes(app)
}

// MARK: - Global Database Reference
var globalDB: Database?

// MARK: - Scheduled Job Example
struct TestJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        context.logger.info("Test Job is running on schedule.")
        print("Test Job is running on schedule.")
    }
}
