//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  
import Foundation
import Fluent
import Vapor

final class Tag: Model, Content, Codable {
    static let schema = "tag"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.title) var title: String

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var title: FieldKey { "title" }
    }
    
    init() { }
    
    init(id: UUID? = nil, title: String) {
        self.id = id
        self.title = title
    }
}

extension TagMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Tag.schema)
            .field(Tag.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Tag.FieldKeys.title, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Tag.schema).delete()
    }
}
