//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//


//struct Board: Codable {
//    var id: UUID
//    var name: String
//    var description: String
//    var columns =  [Column(index: 0, tickets: [], title: "Draft"),
//                    Column(index: 1, tickets: [], title: "Offering"),
//                    Column(index: 2, tickets: [], title: "Preparing"),
//                    Column(index: 3, tickets: [], title: "Manufacturing"),
//                    Column(index: 4, tickets: [], title: "Dispatching"),
//                    Column(index: 5, tickets: [], title: "Invoicing"),
//                    Column(index: 6, tickets: [], title: "Done")]
//    var members: [User]
//    var activity: [Log]
//}

import Foundation
import Fluent
import Vapor

final class Board: Model, Content, Codable {
    static let schema = "board"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.name) var name: String
    @Field(key: FieldKeys.description) var description: String
    @Field(key: FieldKeys.columns) var columns: [Column]
    @Parent(key: "boardID") var board: Board
    @Field(key: FieldKeys.activity) var activity: [Log]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var name: FieldKey { "name" }
        static var description: FieldKey { "description" }
        static var columns: FieldKey { "columns" }
        static var members: FieldKey { "members" }
        static var activity: FieldKey { "activity" }
    }

    init() { }
    
    init(id: UUID? = nil, name: String, description: String, columns: [Column], activity: [Log]) {
        self.id = id
        self.name = name
        self.description = description
        self.columns = columns
        self.activity = activity
    }
}

extension BoardMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Board.schema)
            .field(Board.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Board.FieldKeys.name, .string, .required)
            .field(Board.FieldKeys.description, .string, .required)
            .field(Board.FieldKeys.columns, .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Board.schema).delete()
    }
}
