//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  
import Foundation
import Fluent
import Vapor

final class Brand: Model, Content, Codable {
    static let schema = "brand"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.name) var name: String
    @Field(key: FieldKeys.logo) var logo: String
    @Field(key: FieldKeys.description) var description: String
    @Field(key: FieldKeys.productCount) var productCount: Int
    @Field(key: FieldKeys.images) var images: [String]
    @Children(for: \.$brand) var products: [Product]
    @Children(for: \.$brand) var collections: [Collection]

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var name: FieldKey { "name" }
        static var logo: FieldKey { "logo" }
        static var description: FieldKey { "description" }
        static var productCount: FieldKey { "productCount" }
        static var images: FieldKey { "images" }
    }

    init() { }
    
    init(id: UUID? = nil, name: String, logo: String, description: String, productCount: Int?, images: [String]) {
        self.id = id
        self.name = name
        self.logo = logo
        self.description = description
        self.productCount = productCount ?? 0
        self.images = images
    }
}

extension BrandMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Brand.schema)
            .field(Brand.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Brand.FieldKeys.name, .string, .required)
            .field(Brand.FieldKeys.logo, .string, .required)
            .field(Brand.FieldKeys.description, .string, .required)
            .field(Brand.FieldKeys.productCount, .int, .required)
            .field(Brand.FieldKeys.images, .array(of: .string))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Brand.schema).delete()
    }
}
