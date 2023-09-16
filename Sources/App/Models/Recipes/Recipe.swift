//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation

struct Recipe: Codable {
    let id: UUID
    let title: String
    let image: URL
    let Ingredients: Ingredient
    let description: String
}

struct Ingredient: Codable {
    let name: String
    let substitute: String?
}
