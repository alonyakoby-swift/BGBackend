//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Vapor
import Fluent

final class BrandController: RouteCollection {
    let repository: StandardControllerRepository<Brand>
    
    init(path: String) {
        self.repository = StandardControllerRepository<Brand>(path: path)
    }
    
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        route.post(use: createBrand)
        route.post("batch", use: createBrandBatch)

        route.get(use: repository.index)
        route.get(":id", use: repository.getbyID)
        route.get(":id", "products", use: getBrandWithProducts)
        route.get(":id", "collections", use: getBrandWithCollections)
        route.delete(":id", use: repository.deleteID)
        
        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
        
        route.get("name", ":name", use: getBrandByName)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
    
    func createBrand(req: Request) throws -> EventLoopFuture<Brand> {
        let brand = try req.content.decode(Brand.self)
        return Product.query(on: req.db).count().flatMap { count in
            brand.productCount = count
            return brand.create(on: req.db).map { brand }
        }
    }
    
    func createBrandBatch(req: Request) throws -> EventLoopFuture<[Brand]> {
        let brands = try req.content.decode([Brand].self)
        
        let countFutures = brands.map { brand -> EventLoopFuture<Brand> in
            return Product.query(on: req.db).count().map { count in
                var newBrand = brand
                newBrand.productCount = count
                return newBrand
            }
        }
        
        return EventLoopFuture.whenAllSucceed(countFutures, on: req.eventLoop).flatMap { updatedBrands in
            return updatedBrands.create(on: req.db).transform(to: updatedBrands)
        }
    }

    func getBrandWithProducts(req: Request) throws -> EventLoopFuture<Brand> {
        guard let brandId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "No ID provided")
        }
        
        // Query the Brand model, eager loading its products children
        return Brand.query(on: req.db)
            .filter(\.$id == brandId)
            .with(\.$products)  // Eager load products
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    func getBrandWithCollections(req: Request) throws -> EventLoopFuture<Brand> {
        guard let brandId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "No ID provided")
        }
        
        // Query the Brand model, eager loading its collections children
        return Brand.query(on: req.db)
            .filter(\.$id == brandId)
            .with(\.$collections)  // Eager load collections
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    func getBrandByName(req: Request) throws -> EventLoopFuture<[Brand]> {
        guard let brandName = req.parameters.get("name", as: String.self) else {
            throw Abort(.badRequest, reason: "No name provided")
        }

        let lowercasedBrandName = brandName.lowercased()

        return Brand.query(on: req.db)
            .all()
            .map { brands in
                return brands.filter {
                    $0.name.lowercased().contains(lowercasedBrandName)
                }
            }
    }
    
    // TODO: Function to calculate the product count. (on existing)
}

extension Brand: Mergeable {
    func merge(from other: Brand) -> Brand {
        let merged = self
        merged.name = other.name
        merged.logo = other.logo
        merged.description = other.description
        merged.description = other.description
        merged.productCount = other.productCount
        merged.images = other.images
        return merged
    }
}
