//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Fluent
import Vapor


final class Category: Model, Content, Codable {
    static let schema = "category"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.description) var description: String
    @Field(key: FieldKeys.name) var name: String
    @Field(key: FieldKeys.displayCode) var displayCode: String
    @Children(for: \.$category) var products: [Product]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var description: FieldKey { "description" }
        static var name: FieldKey { "name" }
        static var displayCode: FieldKey { "displayCode" }
    }

    init() { }

    init(id: UUID? = nil, description: String, name: String, displayCode: String) {
        self.id = id
        self.description = description
        self.name = name
        self.displayCode = displayCode
    }
}

// Category Migration
extension CategoryMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Category.schema)
            .field(Category.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Category.FieldKeys.description, .string, .required)
            .field(Category.FieldKeys.name, .string, .required)
            .field(Category.FieldKeys.displayCode, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Category.schema).delete()
    }
}
