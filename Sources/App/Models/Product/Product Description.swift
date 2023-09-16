//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

struct ProductDescription: Codable {
    var language: Language
    var description: String
    
    enum CodingKeys: String, CodingKey {
        case language
        case description = "value"
    }
}
