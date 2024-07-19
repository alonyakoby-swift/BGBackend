//
//  File.swift
//  
//
//  Created by Alon Yakoby on 27.06.24.
//

import Foundation
import Fluent
import Vapor

final class Exception: Model, Content, Codable {
    static let schema = "exceptions"

    @ID(key: .id) var id: UUID?
    @Field(key: "original") var original: String
    @Field(key: "replace") var replace: String

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var original: FieldKey { "original" }
        static var replace: FieldKey { "replace" }
    }

    init() { }

    init(id: UUID? = nil, original: String, replace: String) {
        self.id = id
        self.original = original
        self.replace = replace
    }
}

extension ExceptionMigration: Migration {
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

extension Exception: Mergeable {
    func merge(from other: Exception) -> Exception {
        var merged = self
        merged.original = other.original
        merged.replace = other.replace
        return merged
    }
}
