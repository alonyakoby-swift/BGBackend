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
    static let schema = "selling_points"

    @ID(key: .id) var id: UUID?
    @Field(key: FieldKeys.code) var code: String
    @Field(key: FieldKeys.sellingPoint) var sellingPoint: String

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
