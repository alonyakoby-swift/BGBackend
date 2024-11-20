// swift-tools-version:5.8
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
        // ἳ1 Fluent driver for Mongo.
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.0.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.2.4"),
        .package(url: "https://github.com/Mikroservices/Smtp.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor-community/queues-mongo-driver.git", from: "1.0.0"),
        .package(url: "https://github.com/SwiftOnTheServer/dotenv-swift.git", from: "5.2.0"),

    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "DotenvSwift", package: "dotenv-swift"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Smtp", package: "Smtp"),
                .product(name: "QueuesMongoDriver", package: "queues-mongo-driver"),

            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
