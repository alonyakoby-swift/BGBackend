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
    case pending, inprogress, completed, failed
}

final class Translation: Model, Content, Codable {
    static let schema = "translations"

    @ID(key: .id) var id: UUID?
    @Field(key: FieldKeys.itemCode) var itemCode: String
    @Field(key: FieldKeys.base) var base: String
    @Field(key: FieldKeys.language) var language: Language
    @Field(key: FieldKeys.rating) var rating: Int
    @Field(key: FieldKeys.translation) var translation: String
    @Field(key: FieldKeys.status) var status: TranslationStatus
    
    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var itemCode: FieldKey { "itemCode" }
        static var base: FieldKey { "base" }
        static var language: FieldKey { "language" }
        static var rating: FieldKey { "rating" }
        static var translation: FieldKey { "translation" }
        static var status: FieldKey { "status" }
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case itemCode = "itemCode"
        case base = "base"
        case language = "language"
        case rating = "rating"
        case translation = "translation"
    }

    init() { } 

    init(id: UUID? = nil, itemCode: String, base: String, language: Language, rating: Int, translation: String, status: TranslationStatus) {
        self.id = id
        self.itemCode = itemCode
        self.base = base
        self.language = language
        self.rating = rating
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
            .field(Translation.FieldKeys.translation, .string, .required)
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
        merged.base = other.base
        merged.language = other.language
        merged.rating = other.rating
        merged.translation = other.translation
        return merged
    }
}
