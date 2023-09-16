//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

enum Packaging: String, Codable {
    case box
    case handing
    case sleeve
    
    var name: String {
        switch  self {
            case .box: return "Gift Box"
            case .handing: return  "Handling"
            case .sleeve: return  "Sleeve"
        }
    }
}
