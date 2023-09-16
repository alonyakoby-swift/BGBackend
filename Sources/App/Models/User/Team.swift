//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  
import Foundation
import Fluent
import Vapor

final class Team: Model, Content, Codable {
    static let schema = "team"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.name) var name: String
    @OptionalParent(key: FieldKeys.admin) var admin: User?
    @OptionalParent(key: FieldKeys.board) var board: Board?

    @Siblings(through: UserTeamPivot.self, from: \.$team, to: \.$user)  var members: [User]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var name: FieldKey { "name" }
        static var members: FieldKey { "members" }
        static var admin: FieldKey { "admin" }
        static var board: FieldKey { "board" }
    }

    init() { }
    
    init(id: UUID? = nil, name: String, admin: User.IDValue?, boardID: Board.IDValue?) {
        self.id = id
        self.name = name
        self.$admin.id = admin
        self.$board.id = boardID
    }
}

extension TeamMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Team.schema)
            .field(Team.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Team.FieldKeys.name, .string, .required)
            .field(Team.FieldKeys.admin, .uuid, .references("user", "id"))
            .field(Team.FieldKeys.board, .uuid, .references("board", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Team.schema).delete()
    }
}
