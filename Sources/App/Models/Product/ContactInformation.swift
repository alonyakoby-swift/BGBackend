//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

struct ContactInformation: Codable {
    var name: String
    var email: String
    var description: String?
    var address: Address
    var mobile: String
}

struct Address: Codable {
    var country: Country
    var street: String
    var city: String
    var state: String
    var zip: String
}

enum Country: String, Codable {
    case at
    case de
    case es
    case cn
    case usa
    case canada
    
    
    var displayName: String {
        switch self {
            case .at: return "Austria"
            case .de: return "Germany"
            case .es: return "Spain"
            case .cn: return "Peoples Republic of China"
            case .usa: return "United States of America"
            case .canada: return "Canada"
        }
    }
}
