//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

struct Column: Codable {
    var index: Int
    var tickets: [OrderTicket]
    var title: String
}

