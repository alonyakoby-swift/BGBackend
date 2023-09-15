//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Fluent
import Vapor

final class DBUserVerificationToken: Model, Content {
    
    static let schema = "UserActivationToken"
    
    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var token: FieldKey { "token" }
        static var userID: FieldKey { "userID" }
        static var redeemed: FieldKey { "redeemed" }
    }
    
    init() {}
    
    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.token) var token: String
    @Field(key: FieldKeys.userID) var userID: UUID
    @Field(key: FieldKeys.redeemed) var redeemed: Bool
    
    init(id: UUID? = nil, userID: UUID) {
        self.id = id
        self.token = generateCustomToken(count: 20)
        self.userID = userID
        self.redeemed = false
    }
    
    func generateCustomToken(count: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""
        
        for _ in 0..<count {
            let randomIndex = Int.random(in: 0..<allowedChars.count)
            let randomChar = allowedChars[allowedChars.index(allowedChars.startIndex, offsetBy: randomIndex)]
            randomString.append(randomChar)
        }
        
        return randomString
    }
}

extension DBUserVerificationTokenMigration {
    var schema: String {
        "UserActivationToken"
    }

    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(schema)
            .field(DBUserVerificationToken.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(DBUserVerificationToken.FieldKeys.token, .string)
            .field(DBUserVerificationToken.FieldKeys.userID, .uuid)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(schema).delete()
    }
}
