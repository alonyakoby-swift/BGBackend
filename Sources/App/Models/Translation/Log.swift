//
//  File.swift
//  
//
//  Created by Alon Yakoby on 09.07.24.
//

import Foundation
import Fluent
import Vapor

final class Log: Model, Content, Codable {
    static let schema = "logs"

    @ID(key: .id) var id: UUID?
    @Field(key: "message") var message: String

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var message: FieldKey { "message" }
    }

    init() { }

    init(id: UUID = UUID(), message: String) {
        self.id = id
        self.message = message
    }
}

extension LogMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Log.schema)
            .id()
            .field(Log.FieldKeys.message, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Log.schema).delete()
    }
}

extension Log: Mergeable {
    func merge(from other: Log) -> Log {
        var merged = self
        merged.message = other.message
        return merged
    }
}
