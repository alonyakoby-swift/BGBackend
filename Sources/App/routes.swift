//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Fluent
import Vapor
import Leaf

func routes(_ app: Application) throws {
    let routes: [RouteCollection] = [
        UserController(path: "users"),
        ProductController(path: "products"),
        ExceptionController(path: "exceptions"),
        TranslationController(path: "translations"),
        DeepLController(authKey: globalDeepLkey ?? "")
    ]
    
    app.get("status") { req async -> String in
        "Status Online!"
    }
    
    app.get("stats") { req async throws -> TranslationStatsViewModel in
        let pendingCount = try await Translation.query(on: req.db).filter(\.$status == .pending).count()
        let translatedCount = try await Translation.query(on: req.db).filter(\.$status == .translated).count()
        let completedCount = try await Translation.query(on: req.db).filter(\.$status == .completed).count()
        let productCount = try await Product.query(on: req.db).count()
        
        return TranslationStatsViewModel(pending: pendingCount, translated: translatedCount, completed: completedCount, productCount: productCount)
    }
    
    app.get("analytics") { req async throws -> AnalyticsViewModel in
        let productCount = try await Product.query(on: req.db).count()
        let translationCount = try await Translation.query(on: req.db).count()
        
        let translations = try await Translation.query(on: req.db).all()
        
        var languageStats: [String: Int] = [:]
        translations.forEach { translation in
            let language = translation.language.rawValue
            languageStats[language, default: 0] += 1
        }
        
        return AnalyticsViewModel(productCount: productCount, translationCount: translationCount, languageDistribution: languageStats)
    }
    
    do {
        try routes.forEach { try app.register(collection: $0) }
    } catch {
        print("Routes couldn't be initialized!")
    }
}

struct AnalyticsViewModel: Content {
    let productCount: Int
    let translationCount: Int
    let languageDistribution: [String: Int]
}

struct TranslationStatsViewModel: Content {
    let pending: Int
    let translated: Int
    let completed: Int
    let productCount: Int
}
