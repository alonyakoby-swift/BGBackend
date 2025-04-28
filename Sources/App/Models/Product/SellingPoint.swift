//
//  File.swift
//
//
//  Created by Alon Yakoby on 27.06.24.
//

import Foundation
import Fluent
import Vapor

final class SellingPoint: Model, Content, Codable {
    static let schema = "sellingPoints"

    @ID(key: .id) var id: UUID?
    @Field(key: FieldKeys.code) var code: String
    @Field(key: FieldKeys.sellingPoint) var sellingPoint: String
    @Children(for: \.$sellingPoint) var translations: [Translation]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var code: FieldKey { "code" }
        static var sellingPoint: FieldKey { "sellingPoint" }
    }

    init() { }

    init(id: UUID? = nil, code: String, sellingPoint: String) {
        self.id = id
        self.code = code
        self.sellingPoint = sellingPoint
    }
}

extension SellingPoint {
    func promptText(language: Language, translatedText: String) -> String {
        return """
                I have translated this selling point:
                \(self.sellingPoint)
                
                To this (in \(language.name)):
                \(translatedText)
                
                Please review the translation and check its correctness.

                If the translation is accurate with no suggestions for improvement, respond with "The translation is accurate." and provide a rating from 1 to 10, where 10 indicates perfect accuracy.

                Example response for accurate translations:
                "The translation is accurate."
                Rating: X (where X is a number from 1 to 10)

                If you find inaccuracies or have suggestions for improvement, provide the corrected version along with a rating from 1 to 10.

                Example response for translations needing improvement:
                "Suggested correction: [your suggested correction here]"
                Rating: Y (where Y is a number from 1 to 10 based on accuracy)
        """
    }
}

extension SellingPointMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Exception.schema)
            .id()
            .field(Exception.FieldKeys.original, .string, .required)
            .field(Exception.FieldKeys.replace, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Exception.schema).delete()
    }
}

extension SellingPoint: Mergeable {
    func merge(from other: SellingPoint) -> SellingPoint {
        var merged = self
        merged.code = other.code
        merged.sellingPoint = other.sellingPoint
        return merged
    }
}
