//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Vapor

final class ProductController: RouteCollection {
    let repository: StandardControllerRepository<Product>

    init(path: String) {
        self.repository = StandardControllerRepository<Product>(path: path)
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
    
    // TODO: Get just the available from single and batch
    // TODO: Search for items via ItemCode, Ean, 
}

extension Product: Mergeable {
    func merge(from other: Product) -> Product {
        var merged = self
        merged.itemCode = other.itemCode
        merged.image = other.image
        merged.description = other.description
        merged.status = other.status
        merged.typology = other.typology
        merged.$material.id = other.$material.id
        merged.images = other.images
        merged.$vendor.id = other.$vendor.id
        merged.$brand.id = other.$brand.id
        merged.$subcategory.id = other.$subcategory.id
        merged.cost = other.cost
        merged.pricing = other.pricing
        merged.ean = other.ean
        merged.packaging = other.packaging
        merged.$artwork.id = other.$artwork.id
        merged.available = other.available
        merged.certification = other.certification ?? merged.certification
        merged.distribution = other.distribution
        return merged
    }
}
