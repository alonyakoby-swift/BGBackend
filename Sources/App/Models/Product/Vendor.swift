//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Vapor
import Fluent

final class Vendor: Model, Content, Codable {
    static let schema = "vendor"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.name) var name: String
    @Children(for: \.$vendor) var products: [Product]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var name: FieldKey { "name" }
    }

    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}

extension VendorMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Vendor.schema)
            .field(Vendor.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Vendor.FieldKeys.name, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Vendor.schema).delete()
    }
}
