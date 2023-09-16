//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  


import Foundation
import Fluent
import Vapor

final class OrderTicket: Model, Content, Ticket, Codable {
    static let schema = "order_ticket"
    
    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.type) var type: TicketType
    @Field(key: FieldKeys.dueDate) var dueDate: Date
    @Field(key: FieldKeys.images) var images: [String]
    @Field(key: FieldKeys.files) var files: [File]
    @Parent(key: FieldKeys.customer) var customer: Customer
    @Parent(key: FieldKeys.team) var team: Team
    @Field(key: FieldKeys.memberIDs) var memberIDs: [UUID]
    @Children(for: \.$orderTicket) var products: [OrderProduct]
    
    @Field(key: FieldKeys.title) var title: String
    @Field(key: FieldKeys.status) var status: TicketStatus
    @Field(key: FieldKeys.assignee) var assignee: User
    @Field(key: FieldKeys.creator) var creator: User
    @Field(key: FieldKeys.comments) var comments: [Comment]
    @Field(key: FieldKeys.activity) var activity: [Log]
    
    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var type: FieldKey { "type" }
        static var dueDate: FieldKey { "dueDate" }
        static var images: FieldKey { "images" }
        static var files: FieldKey { "files" }
        static var customer: FieldKey { "customer" }
        static var memberIDs: FieldKey { "memberIDs" }
        static var team: FieldKey { "team" }
        static var title: FieldKey { "title" }
        static var status: FieldKey { "status" }
        static var assignee: FieldKey { "assignee" }
        static var creator: FieldKey { "creator" }
        static var comments: FieldKey { "comments" }
        static var activity: FieldKey { "activity" }
    }
    init()  { }
    
    init(id: UUID? = nil, type: TicketType, dueDate: Date, images: [String], files: [File], customerID: Customer.IDValue, teamID: Team.IDValue, title: String, status: TicketStatus, assignee: User, creator: User, comments: [Comment], activity: [Log], memberIDs: [UUID] = []) {
        self.id = id
        self.type = type
        self.dueDate = dueDate
        self.images = images
        self.files = files
        self.$customer.id = customerID
        self.$team.id = teamID
        self.title = title
        self.status = status
        self.assignee = assignee
        self.creator = creator
        self.comments = comments
        self.activity = activity
        self.memberIDs = memberIDs
    }
}

extension OrderTicketMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(OrderTicket.schema)
            .field(OrderTicket.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(OrderTicket.FieldKeys.type, .string, .required)
            .field(OrderTicket.FieldKeys.dueDate, .date, .required)
            .field(OrderTicket.FieldKeys.images, .array(of: .string))
            .field(OrderTicket.FieldKeys.files, .array(of: .json), .required) // Assuming File is Codable
            .field(OrderTicket.FieldKeys.customer, .uuid, .required, .references("customer", "id"))
            .field(OrderTicket.FieldKeys.team, .uuid, .required, .references("team", "id"))
            .field(OrderTicket.FieldKeys.title, .string, .required)
            .field(OrderTicket.FieldKeys.status, .string, .required) // Assuming TicketStatus is Codable
            .field(OrderTicket.FieldKeys.assignee, .json, .required) // Assuming User is Codable
            .field(OrderTicket.FieldKeys.creator, .json, .required) // Assuming User is Codable
            .field(OrderTicket.FieldKeys.comments, .array(of: .json), .required) // Assuming Comment is Codable
            .field(OrderTicket.FieldKeys.activity, .array(of: .json), .required) // Assuming Log is Codable
            .field(OrderTicket.FieldKeys.memberIDs, .array(of: .uuid))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(OrderTicket.schema).delete()
    }
}
