import Foundation
import Fluent
import Vapor

final class TranslationController: RouteCollection {
    let repository: StandardControllerRepository<Translation>

    init(path: String) {
        self.repository = StandardControllerRepository<Translation>(path: path)
    }

    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        
        route.post(use: repository.create)
        route.post("batch", use: repository.createBatch)

        route.get(use: repository.index)
        route.get(":id", use: repository.getbyID)
        route.get("overview", use: getOverview) // New route for overview
        route.get("item/:itemCode", use: getTranslationsForItemCode) // New route for itemCode

        route.delete(":id", use: repository.deleteID)

        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }

    // New function to get overview of translations
    func getOverview(req: Request) async throws -> TranslationViewModel {
        let pendingCount = try await Translation.query(on: req.db)
            .filter(\.$status == .pending)
            .count()
        
        let translatedCount = try await Translation.query(on: req.db)
            .filter(\.$status == .translated)
            .count()

        let completedCount = try await Translation.query(on: req.db)
            .filter(\.$status == .completed)
            .count()
        
        return TranslationViewModel(pending: pendingCount, translated: translatedCount, completed: completedCount)
    }

    // New function to get translations for a specific item code
    func getTranslationsForItemCode(req: Request) async throws -> [Translation] {
        guard let itemCode = req.parameters.get("itemCode") else {
            throw Abort(.badRequest, reason: "Missing item code parameter")
        }
        
        return try await Translation.query(on: req.db)
            .filter(\.$itemCode == itemCode)
            .all()
    }
}
