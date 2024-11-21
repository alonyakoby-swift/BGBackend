// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "bergnerbackend",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        // Fluent driver for MongoDB.
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
        // 🍃 Vapor's Leaf templating engine.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.2.4"),
        // SMTP package for email.
        .package(url: "https://github.com/Mikroservices/Smtp.git", from: "3.0.0"),
        // Vapor Queues Mongo driver.
        .package(url: "https://github.com/vapor-community/queues-mongo-driver.git", from: "1.0.0"),
        // Environment variable loader.
        .package(url: "https://github.com/swiftpackages/DotEnv.git", from: "3.0.0"),
        // OpenCombine for cross-platform Combine API.
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.12.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "DotEnv", package: "DotEnv"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Smtp", package: "Smtp"),
                .product(name: "QueuesMongoDriver", package: "queues-mongo-driver"),
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine"),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        ),
    ]
)
