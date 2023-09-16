//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  
import Fluent
import Vapor

final class UserTeamPivot: Model {
    static let schema = "user_team_pivot"

    @ID(custom: "id") var id: UUID?
    @Parent(key: "user_id") var user: User
    @Parent(key: "team_id") var team: Team

    init() { }

    init(id: UUID? = nil, userId: User.IDValue, teamId: Team.IDValue) {
        self.id = id
        self.$user.id = userId
        self.$team.id = teamId
    }
}

extension UserTeamPivotMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserTeamPivot.schema)
            .field("id", .uuid, .identifier(auto: true))
            .field("user_id", .uuid, .required, .references("user", "id", onDelete: .cascade))
            .field("team_id", .uuid, .required, .references("team", "id", onDelete: .cascade))
            .unique(on: "user_id", "team_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserTeamPivot.schema).delete()
    }
}
