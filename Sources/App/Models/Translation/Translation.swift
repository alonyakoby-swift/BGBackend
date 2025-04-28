//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Foundation
import Fluent
import Vapor

enum TranslationStatus: String, Codable {
    case pending, formatted, translated, inprogress, completed, failed
}

final class Translation: Model, Content, Codable {
    static let schema = "translations"

    @ID(key: .id) var id: UUID?
    @Parent(key: FieldKeys.product) var product: Product
    @Field(key: FieldKeys.base) var base: String
    @Field(key: FieldKeys.translation) var translation: String
    @Field(key: FieldKeys.language) var language: Language
    @Field(key: FieldKeys.rating) var rating: Int
    @Field(key: FieldKeys.verification) var verification: String?
    @OptionalField(key: FieldKeys.status) var status: TranslationStatus?
    @OptionalField(key: FieldKeys.prompt) var prompt: String?
    @OptionalField(key: FieldKeys.overridenBy) var overridenBy: String?
    @OptionalField(key: FieldKeys.overriden) var overriden: Bool?
    
    struct FieldKeys {
        static var product: FieldKey { "product" }
        static var id: FieldKey { "id" }
        static var itemCode: FieldKey { "itemCode" }
        static var base: FieldKey { "base" }
        static var language: FieldKey { "language" }
        static var rating: FieldKey { "rating" }
        static var translation: FieldKey { "translation" }
        static var verification: FieldKey { "verification" }
        static var status: FieldKey { "status" }
        static var prompt: FieldKey { "prompt" }
        static var overridenBy: FieldKey { "overridenBy"}
        static var overriden: FieldKey { "overriden"}
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case itemCode = "itemCode"
        case base = "base"
        case language = "language"
        case rating = "rating"
        case translation = "translation"
        case verification = "verification"
    }

    init() { } 

    init(id: UUID? = nil, product: Product.IDValue, base: String, language: Language, rating: Int, translation: String, verification: String?, status: TranslationStatus?, prompt: String? = nil, overridenBy: String? = nil, overriden: Bool? = false) {
        self.id = id
        self.$product.id = product
        self.base = base
        self.language = language
        self.rating = rating
        self.verification = verification
        self.translation = translation
        self.status = status
        self.prompt = prompt
        self.overridenBy = overridenBy
        self.overriden = overriden
    }
    
    func verify(manager: TranslationManagerProtocol) async {
        if let id = self.id {
            do {
                try await manager.verifyProductTranslation(translationID: id)
            } catch {
                
            }
        }
    }

}

extension TranslationMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Translation.schema)
            .id()
            .field(Translation.FieldKeys.base, .string, .required)
            .field(Translation.FieldKeys.language, .string, .required)
            .field(Translation.FieldKeys.rating, .int, .required)
            .field(Translation.FieldKeys.translation, .string)
            .field(Translation.FieldKeys.verification, .string)
            .field(Translation.FieldKeys.status, .string)
            .field(Translation.FieldKeys.prompt, .string)
            .field(Translation.FieldKeys.overridenBy, .string)
            .field(Translation.FieldKeys.overriden, .bool)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Translation.schema).delete()
    }
}

extension Translation: Mergeable {
    func merge(from other: Translation) -> Translation {
        var merged = self
        merged.$product.id = other.$product.id
        merged.base = other.base
        merged.language = other.language
        merged.rating = other.rating
        merged.translation = other.translation
        merged.verification = other.verification
        merged.status = other.status
        merged.prompt = other.prompt
        merged.overridenBy = other.overridenBy
        merged.overriden = other.overriden
        return merged
    }
}

import Vapor

struct TranslationViewModel: Content {
    let pending: Int
    let translated: Int
    let completed: Int

    func encodeResponse(for request: Vapor.Request) async throws -> Vapor.Response {
        let response = Response(status: .ok)
        try response.content.encode(self)
        return response
    }
}
