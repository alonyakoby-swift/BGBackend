//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Vapor
import Fluent

enum KPIType: String, Codable {
    case material
    case coating
}

final class KPI: Model, Content, Codable {
    static let schema = "kpi"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.type) var type: KPIType
    @Field(key: FieldKeys.title) var title: String
    @Field(key: FieldKeys.subtitle) var subtitle: String
    @Field(key: FieldKeys.icon) var icon: String

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var type: FieldKey { "type" }
        static var title: FieldKey { "title" }
        static var subtitle: FieldKey { "subtitle" }
        static var icon: FieldKey { "icon" }
    }

    init() { }
    
    init(id: UUID? = nil, type: KPIType, title: String, subtitle: String, icon: String) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
}

extension KPIMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(KPI.schema)
            .field(KPI.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(KPI.FieldKeys.type, .string, .required)
            .field(KPI.FieldKeys.title, .string, .required)
            .field(KPI.FieldKeys.subtitle, .string, .required)
            .field(KPI.FieldKeys.icon, .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(KPI.schema).delete()
    }
}
