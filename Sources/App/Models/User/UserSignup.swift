//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Vapor
import Fluent

struct UserSignup: Content {
    public let firstName: String
    public let lastName: String
    public let email: String
    public let password: String
    public let profileImg: String?
    public let position: String?
    public let permissions: Permissions
    public let type: UserType
    
    init(firstName: String, lastName: String, email: String, password: String, type: UserType, profileImg: String?, permissions: Permissions, position: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.type = type
        self.profileImg = profileImg
        self.permissions = permissions
        self.position = position
    }
}

struct NewSession: Content {
    let token: String
    let user: User.Public
}
