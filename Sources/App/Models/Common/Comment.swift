//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

struct Comment: Codable {
    var id: UUID
    var creator: User
    var content: String
    var images: [String]
    var files: [File]
}
