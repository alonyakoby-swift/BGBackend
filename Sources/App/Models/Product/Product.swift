//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Fluent
import Vapor

final class Product: Model, Content, Codable {
    static let schema = "product"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.itemCode) var itemCode: String
    @Field(key: FieldKeys.image) var image: String
    @Field(key: FieldKeys.description) var description: [ProductDescription]
    @Field(key: FieldKeys.status) var status: ProductStatus
    @Field(key: FieldKeys.typology) var typology: String
    @OptionalParent(key: FieldKeys.material) var material: KPI?
    @Field(key: FieldKeys.images) var images: [String]
    @Field(key: FieldKeys.cost) var cost: Price
    @Field(key: FieldKeys.pricing) var pricing: [Price]
    @Field(key: FieldKeys.ean) var ean: Barcodes
    @Field(key: FieldKeys.packaging) var packaging: String
    @Field(key: FieldKeys.available) var available: Int
    @OptionalField(key: FieldKeys.certification) var certification: String?
    @Field(key: FieldKeys.distribution) var distribution: DistributionData

    @OptionalParent(key: FieldKeys.vendor) var vendor: Vendor?
    @Parent(key: FieldKeys.brand) var brand: Brand
    @Parent(key: FieldKeys.subcategory) var subcategory: Category
    @OptionalParent(key: FieldKeys.artwork) var artwork: File?
    @Parent(key: "categoryID") var category: Category
    @Parent(key: "collectionID") var collection: Collection

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var itemCode: FieldKey { "itemCode" }
        static var image: FieldKey { "image" }
        static var description: FieldKey { "description" }
        static var status: FieldKey { "status" }
        static var typology: FieldKey { "typology" }
        static var material: FieldKey { "material" }
        static var images: FieldKey { "images" }
        static var vendor: FieldKey { "vendor" }
        static var brand: FieldKey { "brand" }
        static var subcategory: FieldKey { "subcategory" }
        static var cost: FieldKey { "cost" }
        static var pricing: FieldKey { "pricing" }
        static var ean: FieldKey { "ean" }
        static var packaging: FieldKey { "packaging" }
        static var artwork: FieldKey { "artwork" }
        static var available: FieldKey { "available" }
        static var certification: FieldKey { "certification" }
        static var distribution: FieldKey { "distribution" }
    }

    init() { }
    
    init(id: UUID? = nil, itemCode: String, image: String, description: [ProductDescription], status: ProductStatus, typology: String, materialID: KPI.IDValue?, images: [String], vendorID: Vendor.IDValue?, brandID: Brand.IDValue, subcategoryID: Category.IDValue, cost: Price, pricing: [Price], ean: Barcodes, packaging: String, artworkID: File.IDValue?, available: Int, certification: String?, distribution: DistributionData) {
        self.id = id
        self.itemCode = itemCode
        self.image = image
        self.description = description
        self.status = status
        self.typology = typology
        self.$material.id = materialID
        self.images = images
        self.$vendor.id = vendorID
        self.$brand.id = brandID
        self.$subcategory.id = subcategoryID
        self.pricing = pricing
        self.cost = cost
        self.ean = ean
        self.packaging = packaging
        self.$artwork.id = artworkID
        self.available = available
        self.certification = certification
        self.distribution = distribution
    }
}

extension ProductMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Product.schema)
            .field(Product.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(Product.FieldKeys.itemCode, .string, .required)
            .field(Product.FieldKeys.image, .string, .required)
            .field(Product.FieldKeys.status, .string, .required)
            .field(Product.FieldKeys.typology, .string, .required)
            .field(Product.FieldKeys.material, .uuid, .required, .references("kpi", "id"))
            .field(Product.FieldKeys.images, .array(of: .string))
            .field(Product.FieldKeys.vendor, .uuid, .references("vendor", "id"))
            .field(Product.FieldKeys.brand, .uuid, .required, .references("brand", "id"))
            .field(Product.FieldKeys.subcategory, .uuid, .required, .references("category", "id"))
            .field(Product.FieldKeys.pricing, .array(of: .json), .required)
            .field(Product.FieldKeys.cost, .json, .required)
            .field(Product.FieldKeys.ean, .json, .required)
            .field(Product.FieldKeys.packaging, .json, .required)
            .field(Product.FieldKeys.artwork, .uuid, .required, .references("file", "id"))
            .field(Product.FieldKeys.available, .int, .required)
            .field(Product.FieldKeys.certification, .string)
            .field(Product.FieldKeys.distribution, .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Product.schema).delete()
    }
}
