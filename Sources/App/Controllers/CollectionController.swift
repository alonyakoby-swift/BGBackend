//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Vapor
import Fluent

final class CollectionController: RouteCollection {
    let repository: StandardControllerRepository<Collection>
    
    init(path: String) {
        self.repository = StandardControllerRepository<Collection>(path: path)
    }
    
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        route.post(use: repository.create)
        route.post("batch", use: repository.createBatch)

        route.get(use: repository.index)
        route.get(":id", use: repository.getbyID)
        route.get(":id", "index", use: getCollectionWithProducts)
        route.delete(":id", use: repository.deleteID)
        
        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
    
    func getCollectionWithProducts(req: Request) throws -> EventLoopFuture<Collection> {
        guard let collectionId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "No ID provided")
        }
        
        return Collection.query(on: req.db)
            .filter(\.$id == collectionId)
            .with(\.$products)
            .first()
            .unwrap(or: Abort(.notFound))
    }

}

extension Collection: Mergeable {
    func merge(from other: Collection) -> Collection {
        let merged = self
        merged.name = other.name
        merged.$brand.id = other.$brand.id
        return merged
    }
}
