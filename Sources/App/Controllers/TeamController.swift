//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Vapor

final class TeamController: RouteCollection {
    let repository: StandardControllerRepository<Team>
    
    init(path: String) {
        self.repository = StandardControllerRepository<Team>(path: path)
    }
    
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        route.post(use: createTeamWithBoards)
        route.post("batch", use: createMultipleTeamsWithBoards)

        route.get(use: repository.index)
        route.get(":id", use: repository.getbyID)
        route.delete(":id", use: repository.deleteID)
        
        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
    
    func createTeamWithBoards(req: Request) throws -> EventLoopFuture<Team> {
        let team = try req.content.decode(Team.self)
        let board = Board(name: team.name,
                          description: team.description,
                          columns: [Column(index: 1, tickets: [], title: "Todo"),
                                    Column(index: 2, tickets: [], title: "In Progress"),
                                    Column(index: 3, tickets: [], title: "Blocked"),
                                    Column(index: 4, tickets: [], title: "Done")],
                          activity: [])
        
        return board.create(on: req.db).flatMap { _ in
            team.$board.id = board.id
            return team.create(on: req.db).transform(to: team)
        }
    }

    func createMultipleTeamsWithBoards(req: Request) throws -> EventLoopFuture<[Team]> {
        let teams = try req.content.decode([Team].self)
        let teamFutures = teams.map { team -> EventLoopFuture<Team> in
            let board = Board(name: team.name,
                              description: team.description,
                              columns: [Column(index: 1, tickets: [], title: "Todo"),
                                        Column(index: 2, tickets: [], title: "In Progress"),
                                        Column(index: 3, tickets: [], title: "Blocked"),
                                        Column(index: 4, tickets: [], title: "Done")],
                              activity: [])
            
            return board.create(on: req.db).flatMap { _ in
                team.$board.id = board.id
                return team.create(on: req.db).transform(to: team)
            }
        }
        
        return EventLoopFuture.whenAllSucceed(teamFutures, on: req.eventLoop)
    }
    
    /*
     TODO: [x]
     [] ADD USER TO TEAM
     [] GET TEAM WITH BOARD
     [] REMOVE USER TO BOARD 
     */
}

extension Team: Mergeable {
    func merge(from other: Team) -> Team {
        let merged = self
        merged.name = other.name
        merged.$admin.id = other.$admin.id
        merged.$board.id = other.$board.id
//        merged.members = other.members
        return merged
    }
}
