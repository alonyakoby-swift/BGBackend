//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

// Make Model
struct Warehouse: Codable {
    var id: UUID
    var name: String
    var products: [WarehouseProduct]
}
