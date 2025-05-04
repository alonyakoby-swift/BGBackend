import Vapor
import Fluent
import FluentMongoDriver
import Leaf
import Queues
import QueuesMongoDriver
import MongoKitten

enum AppMode {
    case development, production
}
public func configure(_ app: Application) throws {
    
    var mode: AppMode = .production
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
    let databaseURL: String
    if mode == .development {
        databaseURL = ENV.databaseURL.dev_default
    } else {
        guard let envURL = Environment.get("CONNECTION_STRING") else {
            fatalError("CONNECTION_STRING not set in environment variables for production")
        }
        databaseURL = envURL
    }

    var mongoConnectionString = databaseURL
    if mongoConnectionString.contains("digitalocean") && !mongoConnectionString.contains("authSource") {
        mongoConnectionString += "?authSource=admin"
    }
    app.logger.info("Connecting to MongoDB at: \(mongoConnectionString)")

    // Register MongoDB for Fluent
    try app.databases.use(.mongo(connectionString: mongoConnectionString), as: .mongo)

    // MARK: - Leaf Configuration
    app.views.use(.leaf)

    // MARK: - Middleware Configuration
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    let allowedOrigins: [String] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:4000",
        "http://localhost:4001",
        "http://localhost:5500",
        "http://localhost:4500",
        "https://bg-frontend-oi4hx.ondigitalocean.app"
    ]
    let cors = CustomCORSMiddleware(
        allowedOrigins: allowedOrigins,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [
            "Authorization","Content-Type","Accept","Origin",
            "X-Requested-With","User-Agent","sec-ch-ua",
            "sec-ch-ua-mobile","sec-ch-ua-platform"
        ],
        allowCredentials: true
    )
    app.middleware.use(cors)

    // MARK: - MongoKitten & Queues Configuration
    do {
        let mongoDatabase = try MongoDatabase.connect(mongoConnectionString, on: app.eventLoopGroup.next()).wait()
        try app.queues.use(.mongodb(mongoDatabase))
        try app.queues.startScheduledJobs()
    } catch {
        app.logger.error("Failed to connect to MongoDB queues: \(error.localizedDescription)")
        fatalError("Failed to connect to MongoDB for queues")
    }

    // MARK: - API Keys & Managers
    guard let openAIApiKey = Environment.get("OPENAI_API_KEY") else {
        fatalError("OPENAI_API_KEY not set in environment variables")
    }
    let deepLKey = Environment.get("DEEPL_API_KEY") ?? ""

    let ollama = OllamaManager()
    let openAI = OpenAIManager(apiKey: openAIApiKey)
    let deepSeek = DeepSeekManager(apiKey: Environment.get("DEEPSEEK_API_KEY") ?? "")
    globalTranslationManager = TranslationManager(
        db: app.db,
        authKey: deepLKey,
        aiManager: AIManager(
            ollama: ollama,
            openAI: openAI,
            deepseek: deepSeek,
            model: .deepseek
        )
    )

    // MARK: - Migrations
    app_migrations.forEach { app.migrations.add($0) }
    try app.autoMigrate().wait()

    // MARK: - Routes
    try routes(app)
}

// MARK: - Scheduled Job Example
struct TestJob: AsyncScheduledJob {
    func run(context: QueueContext) async throws {
        context.logger.info("Test Job is running on schedule.")
        print("Test Job is running on schedule.")
    }
}
