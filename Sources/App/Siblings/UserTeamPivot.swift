//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  
import Fluent
import Vapor

<<<<<<< Updated upstream
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
=======
import Foundation
import Vapor
import Fluent

final class UserTeamPivot: Model {
    static let schema: String = "user_team_pivot"
    
    @ID var id: UUID?
    @Parent(key: "userID") var user: User
    @Parent(key: "teamID") var team: Team
    
    init() {}
    
    init(id: UUID? = nil, userID: UUID, teamID: UUID) {
        self.id = id
        self.$user.id = userID
        self.$team.id = teamID
>>>>>>> Stashed changes
    }
}

extension UserTeamPivotMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
<<<<<<< Updated upstream
        return database.schema(UserTeamPivot.schema)
            .field("id", .uuid, .identifier(auto: true))
            .field("user_id", .uuid, .required, .references("user", "id", onDelete: .cascade))
            .field("team_id", .uuid, .required, .references("team", "id", onDelete: .cascade))
            .unique(on: "user_id", "team_id")
=======
        database.schema("user_team_pivot")
            .field("id", .uuid, .identifier(auto: true))
            .field("userID", .uuid, .required, .references("user", "id"))
            .field("teamID", .uuid, .required, .references("team", "id"))
>>>>>>> Stashed changes
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
<<<<<<< Updated upstream
        return database.schema(UserTeamPivot.schema).delete()
=======
        database.schema("user_team_pivot").delete()
>>>>>>> Stashed changes
    }
}
