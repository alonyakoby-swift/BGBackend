//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Vapor
import Fluent
import FluentMongoDriver
import Leaf
//import Smtp
import Queues
import QueuesMongoDriver
import MongoKitten
//import JWT

extension String {
    var bytes: [UInt8] { .init(self.utf8) }
}
// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    //    app.jwt.signers.use(.hs256(key: "3Cz30pJzxbqYvLjXqTJjU8VpU5bxvgoNRvq1a+BXOts"))
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)
    
//    app.jwt.signers.use(.hs256(key: Environment.get(ENV.jwtSecret.key) ?? ENV.jwtSecret.dev_default))

    
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    
    try app.databases.use(.mongo(connectionString:Environment.get(ENV.databaseURL.key) ?? ENV.databaseURL.dev_default),
                          as: .mongo)
 
    app_migrations.forEach { app.migrations.add($0) }
    
    try app.autoMigrate().wait()
 
    app.views.use(.leaf)
//    app.middleware.use(DBUser.authenticator())
//    app.middleware.use(Token.authenticator())

    
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.passwords.use(.bcrypt)

    // Configure multiple allowed origins
    let allowedOrigins: [String] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:4000",
        "http://localhost:4001",
        "http://localhost:5500",
        "http://localhost:4500"
    ]

    // Define your CORS configuration
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

    // Create the CORS middleware with the configuration
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(corsMiddleware) // Move this after ErrorMiddleware

    // Use the CORS middleware in your application
    app.middleware.use(corsMiddleware, at: .beginning) // Ensure it's the first middleware to run
//    let backgroundManager = BackgroundManager(eventLoop: app.eventLoopGroup.next(), db: app.db, authKey: deepLkey) 
    //Environment.get("DEEPL_API_KEY") ?? "your-deepl-api-key")

    let mongoConnectionString = Environment.get(ENV.databaseURL.key) ?? ENV.databaseURL.dev_default
    let mongoDatabase = try MongoDatabase.connect(mongoConnectionString, on: app.eventLoopGroup.next()).wait()

    // Setup Queues with MongoDB driver
    try app.queues.use(.mongodb(mongoDatabase))

    globalDB = app.db
    
    guard let deepLkey = Environment.get("DEEPL_API_KEY") else {
        return
    }
    
    // MARK: AI MANAGERS
    
    let ollama = OllamaManager()
    guard let openAIApikey = Environment.get("OPENAI_API_KEY") else { return }
    let openAI = OpenAIManager(apiKey: openAIApikey)
    
    globalTranslationManager = TranslationManager(db: app.db, authKey: deepLkey, aiManager: AIManager(ollama: ollama, openAI: openAI, model: .openAI))

    app.queues.schedule(TestJob())
       .weekly()
       .on(.monday)
       .at(8,0)

    // Start the scheduled jobs
    try app.queues.startScheduledJobs()

    // register routes
    try routes(app)
}

var globalDB: Database?

struct TestJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        context.logger.info("Test Job is running every second.")
        print("Test Job is running every second.")
    }
}

/* struct UnlockPlayerJob: AsyncScheduledJob {
 func run(context: QueueContext) async throws {
     context.logger.info("Unlock Job is running.")
     print("Unlock Job is running.")

     // Job logic
     // Get all the players with eligibility Gesperrt, Check if their blockdate has passed, if yes set their eligibility to Spielberechtigt
     let players = try await Player.query(on: context.application.db)
         .filter(\.$eligibility == .Gesperrt)
         .filter(\.$blockdate <= Date())
         .all()
     
     for player in players {
         player.eligibility = .Spielberechtigt
         try await player.save(on: context.application.db)
         context.logger.info("Player \(player.name) eligibility updated to Spielberechtigt.")
     }
 }
} */


