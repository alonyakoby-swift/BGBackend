//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

protocol Ticket: Codable {
    var id: UUID? { get }
    var title: String { get }
    var description: String { get }
    var type: TicketType { get }
    var status: TicketStatus { get }
    var assignee: User { get }
    var creator: User  { get }
    var comments: [Comment]  { get }
    var activity: [Log]  { get }
}
