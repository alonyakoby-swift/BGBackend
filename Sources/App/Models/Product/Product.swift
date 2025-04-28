//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Foundation
import Fluent
import Vapor

final class Product: Model, Content, Codable {
    static let schema = "products"

    @ID(key: .id) var id: UUID?
    @Field(key: FieldKeys.code) var code: String?
    @Field(key: FieldKeys.name) var name: String?
    @Field(key: FieldKeys.description) var description: String
    @Timestamp(key: FieldKeys.created, on: .create) var created: Date?
    @Timestamp(key: FieldKeys.modified, on: .update) var modified: Date?

    @Children(for: \.$product) var translations: [Translation]
    
    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var code: FieldKey { "code" }
        static var name: FieldKey { "name" }
        static var description: FieldKey { "description" }
        static var created: FieldKey { "created" }
        static var modified: FieldKey { "modified" }
    }

    init() { }

    init(id: UUID? = nil, code: String?, name: String?, description: String, created: Date?, modified: Date?) {
        self.id = id
        self.code = code
        self.name = name
        self.description = description
        self.created = created
        self.modified = modified
        
    }
}


extension ProductMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Product.schema)
            .id()
            .field(Product.FieldKeys.code, .string)
            .field(Product.FieldKeys.name, .string, .required)
            .field(Product.FieldKeys.description, .string)
            .field(Product.FieldKeys.created, .string)
            .field(Product.FieldKeys.modified, .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Product.schema).delete()
    }
}

extension Product: Mergeable {
    func merge(from other: Product) -> Product {
        var merged = self
        merged.code = other.code ?? self.code
        merged.name = other.name ?? self.name
        merged.description = other.description ?? self.description
        merged.created = other.created ?? self.created
        merged.modified = other.modified ?? self.modified
        return merged
    }
}

extension Product {
    func isEqualTo(_ other: Product) -> Bool {
        return self.code == other.code &&
            self.name == other.name &&
        self.description == other.description
    }
    
    func promptText(language: Language, translatedText: String) -> String {
        return """
                    I have translated this string:
                    \(self.description ?? "Error in Fetching Description")
                    
                    To this (in \(language.name)):
                    \(translatedText)
                    
                    Please review the translations and check their correctness.

                    If you find the translation to be accurate and do not have any suggestions for improvement, please indicate this by responding with "The translation is accurate." and provide a rating from 1 to 10, where 10 is the highest level of accuracy.

                    Example response for accurate translations:
                    "The translation is accurate." (Also please make sure to in addition to that string add comments if there is something that may be translated for ex: as the name of the Collection is "BG NATURAL" and it translated to "BG NATÜRLICH" which was not intended. 
                    Rating: X (where X is a number from 1 to 10 indicating the accuracy of the translation)

                    If you identify any inaccuracies or have suggestions for improving the translation, please provide the corrected version or your suggestions along with a rating from 1 to 10, where 10 represents a perfect translation and 1 indicates significant inaccuracies.

                    Example response for translations needing improvement:
                    "Suggested correction: [your suggested correction here]"
                    Rating: Y (where Y is a number from 1 to 10 based on the suggested improvement's accuracy)
        """
    }
    
    func formatText(manager: TranslationManagerProtocol) async {
        if let id = self.id {
            do {
//                try await manager.formatText(productID: id)
            } catch {
                
            }
        }
    }
}

/*
 - Create on Post from Togo -> Start Chain of formatting, translating and verifying the translation.
 - Get products creater or mofidied by since
 - ** Make sure to set the same time zone as the server and China are in different timse zone.
 - Get by single product with all translations
 - 
 */
