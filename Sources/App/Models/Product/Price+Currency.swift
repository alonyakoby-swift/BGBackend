//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

struct Price: Codable {
//    var currency: Currency
    var currency: String
    var title: String
    var value: Double
}
enum Currency: Codable {
    case euro
    case usd
    
    var symbol: String {
        switch self {
            case .euro: return "€"
            case .usd: return "$"
        }
    }
    
    var name: String  {
        switch self {
            case .euro: return "Euro"
            case .usd:  return "United States Dollar"
        }
    }
}
