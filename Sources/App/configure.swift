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
    guard let databaseURL = Environment.get("DATABASE_URL") else {
        fatalError("DATABASE_URL not set in environment variables")
    }
    try app.databases.use(.mongo(connectionString: databaseURL), as: .mongo)

    // MARK: - Leaf Configuration
    app.views.use(.leaf)

    // MARK: - Middleware Configuration
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    app.passwords.use(.bcrypt)

    // MARK: - MongoKitten Configuration
    let mongoDatabase = try MongoDatabase.connect(databaseURL, on: app.eventLoopGroup.next()).wait()
    try app.queues.use(.mongodb(mongoDatabase))

    // MARK: - API Keys
    guard let deepLKey = Environment.get("DEEPL_API_KEY") else {
        fatalError("DEEPL_API_KEY not set in environment variables")
    }
    guard let openAIApiKey = Environment.get("OPENAI_API_KEY") else {
        fatalError("OPENAI_API_KEY not set in environment variables")
    }

    // Add your remaining configurations here...

    // MARK: - Routes
    try routes(app)
}
