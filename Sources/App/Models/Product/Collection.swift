//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Fluent
import Vapor

final class Collection: Model, Content, Codable {
    static let schema = "collection"
    
    @ID(custom: FieldKeys.id) var id: UUID?
    @OptionalParent(key: FieldKeys.brand) var brand: Brand?
    @Field(key: FieldKeys.name) var name: String
    @Children(for: \.$collection) var files: [File]
    @Children(for: \.$collection) var products: [Product]
    
    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var brand: FieldKey { "brand" }
        static var name: FieldKey { "name" }
    }
    
    init() { }
    
    init(id: UUID? = nil, brandID: Brand.IDValue?, name: String) {
        self.id = id
        self.$brand.id = brandID
        self.name = name
    }
}

extension CollectionMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Collection.schema)
            .field(Collection.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Collection.FieldKeys.brand, .uuid, .references("brand", "id"))
            .field(Collection.FieldKeys.name, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Collection.schema).delete()
    }
}
