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
    @Field(key: FieldKeys.itemCode) var itemCode: String
    @Field(key: FieldKeys.base) var base: String
    @Field(key: FieldKeys.language) var language: Language
    @Field(key: FieldKeys.rating) var rating: Int
    @Field(key: FieldKeys.verification) var verification: String?
    @Field(key: FieldKeys.translation) var translation: String
    @OptionalField(key: FieldKeys.status) var status: TranslationStatus?
    
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

    init(id: UUID? = nil, product: Product.IDValue, itemCode: String, base: String, language: Language, rating: Int, translation: String, verification: String?, status: TranslationStatus?) {
        self.id = id
        self.$product.id = product
        self.itemCode = itemCode
        self.base = base
        self.language = language
        self.rating = rating
        self.verification = verification
        self.translation = translation
        self.status = status
    }
}

extension TranslationMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Translation.schema)
            .id()
            .field(Translation.FieldKeys.itemCode, .string, .required)
            .field(Translation.FieldKeys.base, .string, .required)
            .field(Translation.FieldKeys.language, .string, .required)
            .field(Translation.FieldKeys.rating, .int, .required)
            .field(Translation.FieldKeys.translation, .string)
            .field(Translation.FieldKeys.verification, .string)
            .field(Translation.FieldKeys.status, .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Translation.schema).delete()
    }
}

extension Translation: Mergeable {
    func merge(from other: Translation) -> Translation {
        var merged = self
        merged.itemCode = other.itemCode
        merged.$product.id = other.$product.id
        merged.base = other.base
        merged.language = other.language
        merged.rating = other.rating
        merged.translation = other.translation
        merged.verification = other.verification
        merged.status = other.status
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
