//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Vapor

final class CustomerController: RouteCollection {
    let repository: StandardControllerRepository<Customer>
    
    init(path: String) {
        self.repository = StandardControllerRepository<Customer>(path: path)
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

extension Customer: Mergeable {
    func merge(from other: Customer) -> Customer {
        let merged = self
        merged.companyName = other.companyName
        merged.contacts = other.contacts
        merged.website = other.website
        return merged
    }
}
