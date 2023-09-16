//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Fluent
import Vapor

final class Customer: Model, Content, Codable {
    static let schema = "customer"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.companyName) var companyName: String
    @Field(key: FieldKeys.website) var website: String
    @Field(key: FieldKeys.contacts) var contacts: [ContactInformation]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var companyName: FieldKey { "companyName" }
        static var website: FieldKey { "website" }
        static var contacts: FieldKey { "contacts" }
    }

    init() { }
    init(id: UUID? = nil, companyName: String, website: String) {
        self.id = id
        self.companyName = companyName
        self.website = website
    }
}

extension CustomerMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Customer.schema)
            .field(Customer.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Customer.FieldKeys.companyName, .string, .required)
            .field(Customer.FieldKeys.website, .string, .required)
            .field(Customer.FieldKeys.contacts, .array(of: .json), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Customer.schema).delete()
    }
}
