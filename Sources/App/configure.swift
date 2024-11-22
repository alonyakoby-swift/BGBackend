import Vapor
import Fluent
import FluentMongoDriver
import Leaf
import Queues
import QueuesMongoDriver
import MongoKitten

public func configure(_ app: Application) throws {
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
    guard let databaseURL = Environment.get("CONNECTION_STRING") else {
        fatalError("DATABASE_URL not set in environment variables")
    }
    
    // Adjust database URL based on whether it is local or remote (e.g., DigitalOcean)
    var mongoConnectionString = databaseURL
    if mongoConnectionString.contains("digitalocean") {
        if !mongoConnectionString.contains("authSource") {
            mongoConnectionString += "?authSource=admin"
        }
    }

    app.logger.info("Connecting to MongoDB at: \(mongoConnectionString)")

    try app.databases.use(.mongo(connectionString: mongoConnectionString), as: .mongo)

    // MARK: - Leaf Configuration
    app.views.use(.leaf)

    // MARK: - Middleware Configuration
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.passwords.use(.bcrypt)

    // MARK: - MongoKitten Configuration
    do {
        let mongoDatabase = try MongoDatabase.connect(mongoConnectionString, on: app.eventLoopGroup.next()).wait()
        try app.queues.use(.mongodb(mongoDatabase))
    } catch {
        app.logger.error("Failed to connect to MongoDB: \(error.localizedDescription)")
        fatalError("Failed to connect to MongoDB")
    }

    // MARK: - API Keys
    guard let deepLKey = Environment.get("DEEPL_API_KEY") else {
        fatalError("DEEPL_API_KEY not set in environment variables")
    }
    guard let openAIApiKey = Environment.get("OPENAI_API_KEY") else {
        fatalError("OPENAI_API_KEY not set in environment variables")
    }

    app_migrations.forEach { app.migrations.add($0) }
    try app.autoMigrate().wait()

    // Configure multiple allowed origins
    let allowedOrigins: [String] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:4000",
        "http://localhost:4001",
        "http://localhost:5500",
        "http://localhost:4500",
        "https://bg-frontend-oi4hx.ondigitalocean.app"
    ]
    
    // Initialize the custom CORS middleware
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

    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.middleware.use(corsMiddleware) // Move this after ErrorMiddleware
    let mongoDatabase = try MongoDatabase.connect(mongoConnectionString, on: app.eventLoopGroup.next()).wait()

    
    let ollama = OllamaManager()
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

    // Setup Queues with MongoDB driver
    try app.queues.use(.mongodb(mongoDatabase))

    // Start the scheduled jobs
    try app.queues.startScheduledJobs()

    // Register routes
    try routes(app)
}

// MARK: - Scheduled Job Example
struct TestJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        context.logger.info("Test Job is running on schedule.")
        print("Test Job is running on schedule.")
    }
}
