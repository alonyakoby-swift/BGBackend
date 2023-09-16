//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Vapor

final class CategoryController: RouteCollection {
    let repository: StandardControllerRepository<Category>
    
    init(path: String) {
        self.repository = StandardControllerRepository<Category>(path: path)
    }
    
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        route.post(use: repository.create)
        route.post("batch", use: repository.createBatch)

        route.get(use: repository.index)
        route.get(":id", use: repository.getbyID)
        route.delete(":id", use: repository.deleteID)
        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
}

extension Category: Mergeable {
    func merge(from other: Category) -> Category {
        let merged = self
        merged.description = other.description
        merged.name = other.name
        merged.displayCode = other.displayCode
        return merged
    }
}
