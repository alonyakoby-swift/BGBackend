//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Foundation
import Vapor
import Fluent

enum Region: String, Codable {
    case eu
    
    var name: String {
        switch self {
        case .eu: return "Europe"
        }
    }
}

final class Certificate: Model, Content, Codable {
    static let schema = "certificates"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.code) var code: String
    @Field(key: FieldKeys.region) var region: Region
    @Field(key: FieldKeys.official) var official: String
    @Field(key: FieldKeys.source) var source: String?
    @Field(key: FieldKeys.icon) var icon: String?


    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var code: FieldKey { "code" }
        static var region: FieldKey { "region" }
        static var official: FieldKey { "official" }
        static var source: FieldKey { "source" }
        static var icon: FieldKey { "icon" }
        static var link: FieldKey { "link" }
    }

    init() { }
    init(id: UUID? = nil, code: String, region: Region, official: String, source: String, icon: String?) {
        self.id = id
        self.code = code
        self.region = region
        self.official = official
        self.source = source
        self.icon = icon
   }
}

extension CertificateMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Certificate.schema)
            .field(Certificate.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Certificate.FieldKeys.code, .string, .required)
            .field(Certificate.FieldKeys.region, .json, .required)
            .field(Certificate.FieldKeys.official, .string, .required)
            .field(Certificate.FieldKeys.source, .string)
            .field(Certificate.FieldKeys.icon, .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(File.schema).delete()
    }
}

extension Certificate: Mergeable {
    func merge(from other: Certificate) -> Certificate {
        let merged = self
        return merged
    }
}
