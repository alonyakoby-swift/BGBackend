//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

enum Language: String, Codable {
    case en
    case de
    case es
    
    var name: String {
        switch self {
            case .en: return "English"
            case .de: return "Deutsch"
            case .es: return "Spanish"
        }
    }
}
