//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  
import Foundation
import Fluent
import Vapor

struct Permissions: Codable {
    var readProducts: Bool
    var readUsers: Bool
    var updateUsers: Bool
    var createUsers: Bool
    var writeProducts: Bool
    var overrideTranslations: Bool
    
    init(readProducts: Bool?, readUsers: Bool?, updateUsers: Bool?, createUsers: Bool?, writeProducts: Bool?, overrideTranslations: Bool?) {
        self.readProducts = readProducts ?? false
        self.readUsers = readUsers ?? false
        self.updateUsers = updateUsers ?? false
        self.createUsers = createUsers ?? false
        self.writeProducts = writeProducts ?? false
        self.overrideTranslations = overrideTranslations ?? false
    }
    
}

final class User: Model, Content, Codable {
    static let schema = "user"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.type) var type: UserType
    @Field(key: FieldKeys.firstName) var firstName: String
    @Field(key: FieldKeys.lastName) var lastName: String
    @Field(key: FieldKeys.email) var email: String
    @Field(key: FieldKeys.permissions) var permissions: Permissions
    @OptionalField(key: FieldKeys.position) var position: String?
    @OptionalField(key: FieldKeys.profileImg) var profileImg: String?
    @Field(key: FieldKeys.passwordHash) var passwordHash: String
    
    struct Public: Content, Codable {
        let id: UUID
        let email: String
        let type: UserType
        let passwordHash: String
        let name: String
        let position: String
        let image: String?
    }

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var type: FieldKey { "type" }
        static var firstName: FieldKey { "firstName" }
        static var lastName: FieldKey { "lastName" }
        static var email: FieldKey { "email" }
        static var permissions: FieldKey { "permissions" }
        static var profileImg: FieldKey { "profileImg" }
        static var position: FieldKey { "position" }
        static var passwordHash: FieldKey { "passwordHash" }
    }

    init() {}
    
    init(id: UUID? = nil, type: UserType, firstName: String, lastName: String, email: String, passwordHash: String, permissions: Permissions, profileImg: String?, position: String?) {
        self.id = id
        self.type = type
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
        self.permissions = permissions
        self.profileImg = profileImg
        self.position = position
    }
}

extension UserMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema)
            .field(User.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(User.FieldKeys.type, .string, .required)
            .field(User.FieldKeys.firstName, .string, .required)
            .field(User.FieldKeys.lastName, .string, .required)
            .field(User.FieldKeys.email, .string, .required)
            .field(User.FieldKeys.passwordHash, .string, .required)
            .field(User.FieldKeys.profileImg, .string)
            .field(User.FieldKeys.position, .string)
            .field(User.FieldKeys.permissions, .json)
            .unique(on: User.FieldKeys.email)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema).delete()
    }
}

enum UserType: String, Codable {
    case admin
    case staff
    case manager
}

extension User: Authenticatable {
    static func create(from userSignup: UserSignup) throws -> User {
        User(type: userSignup.type,
             firstName: userSignup.firstName,
             lastName: userSignup.lastName,
             email: userSignup.email,
             passwordHash: try Bcrypt.hash(userSignup.password), 
             permissions: userSignup.permissions,
             profileImg: userSignup.profileImg,
             position: userSignup.position)
    }
    
    func createToken(source: SessionSource) throws -> Token {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        return try Token(userId: requireID(),
                         token: [UInt8].random(count: 16).base64,
                         source: source,
                         expiresAt: expiryDate)
    }
    
    func asPublic() throws -> Public {
        Public(id: try requireID(),
               email: email,
               type: type,
               passwordHash: passwordHash,
               name: firstName + " " + lastName,
               position: position ?? "",
               image: profileImg)
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        print("Input password: \(password)")
        print("Hashed password: \(self.passwordHash)")
        let result = try Bcrypt.verify(password, created: self.passwordHash)
        print("Password verification result: \(result)")
        return result
    }
}

