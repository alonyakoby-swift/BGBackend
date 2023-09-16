//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

enum SalesTypology: String, Codable {
    case assortment
    case loyalty
    case shopInShop
    case tailorMade
    
    var name: String {
        switch self {
        case .assortment: return "Assortment"
        case .loyalty: return "Loyalty"
        case .shopInShop: return "Shop In Shop"
        case .tailorMade: return "Tailor made"
        }
    }
}
