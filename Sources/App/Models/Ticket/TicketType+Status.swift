//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

enum TicketType: String, Codable {
    case task
    case order
    case request
    case procurement
}

enum TicketStatus: String, Codable {
    case toDo = "Todo"
    case inProgress = "In Progress"
    case done = "Done"
    case blocked = "Blocked"
    case cancelled = "Cancelled"
}
