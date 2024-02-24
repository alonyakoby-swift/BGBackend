//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

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
    }
}

extension UserTeamPivotMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user_team_pivot")
            .field("id", .uuid, .identifier(auto: true))
            .field("userID", .uuid, .required, .references("user", "id"))
            .field("teamID", .uuid, .required, .references("team", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserTeamPivot.schema).delete()
    }
}
