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
    static let schema = "products"

    @ID(key: .id) var id: UUID?
    @Field(key: "IDArticle") var IDArticle: String?
    @Field(key: "CodArticle") var CodArticle: String
    @Field(key: "Description") var Description: String?
    @Field(key: "Category") var Category: String?
    @Field(key: "CategoryEN") var CategoryEN: String?
    @Field(key: "CategoryIT") var CategoryIT: String?
    @Field(key: "SubCategory") var SubCategory: String?
    @Field(key: "SubCategoryEN") var SubCategoryEN: String?
    @Field(key: "SubCategoryIT") var SubCategoryIT: String?
    @Field(key: "Brand") var Brand: String?
    @Field(key: "LifePhase") var LifePhase: String?
    @Field(key: "OnlineTitle") var OnlineTitle: String?
    @Field(key: "OnlineTitleEN") var OnlineTitleEN: String?
    @Field(key: "OnlineTitleIT") var OnlineTitleIT: String?
    @Field(key: "ProductDescriptionLong") var ProductDescriptionLong: String?
    @Field(key: "ProductDescriptionLongEN") var ProductDescriptionLongEN: String?
    @Field(key: "Chains") var Chains: String?
    @Field(key: "HeightMasterBox") var HeightMasterBox: Double?
    @Field(key: "WidthMasterBox") var WidthMasterBox: Double?
    @Field(key: "LongMasterBox") var LongMasterBox: Double?
    @Field(key: "NetWeightMasterBox") var NetWeightMasterBox: Double?
    @Field(key: "GrossWeightMasterBox") var GrossWeightMasterBox: Double?
    @Field(key: "HeightInnerBox") var HeightInnerBox: Double?
    @Field(key: "WidthInnerBox") var WidthInnerBox: Double?
    @Field(key: "LongInnerBox") var LongInnerBox: Double?
    @Field(key: "NetWeightInnerBox") var NetWeightInnerBox: Double?
    @Field(key: "GrossWeightInnerBox") var GrossWeightInnerBox: Double?
    @Field(key: "HeightArticle") var HeightArticle: Double?
    @Field(key: "WidthArticle") var WidthArticle: Double?
    @Field(key: "LongArticle") var LongArticle: Double?
    @Field(key: "NetWeightArticle") var NetWeightArticle: Double?
    @Field(key: "GrossWeightArticle") var GrossWeightArticle: Double?
    @Field(key: "EAN13Article") var EAN13Article: String?
    @Field(key: "ProductDescriptionEN") var ProductDescriptionEN: String?
    @Field(key: "ProductDescriptionIT") var ProductDescriptionIT: String?
    @Field(key: "PSCategory") var PSCategory: String?
    @Field(key: "PSSubCategory") var PSSubCategory: String?
    @Field(key: "PSCategoryEN") var PSCategoryEN: String?
    @Field(key: "PSSubCategoryEN") var PSSubCategoryEN: String?
    @Field(key: "ProductLine") var ProductLine: String?
    @Field(key: "GHSCode") var GHSCode: String?
    @Field(key: "CountryOfOrigin") var CountryOfOrigin: String?
    @Field(key: "ProductStatus") var ProductStatus: String?
    @Field(key: "Price") var Price: Int?
    @Field(key: "AvailableStock") var AvailableStock: Int?
    @Field(key: "Files") var Files: [File]?

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var IDArticle: FieldKey { "IDArticle" }
        static var CodArticle: FieldKey { "CodArticle" }
        static var Description: FieldKey { "Description" }
        static var Category: FieldKey { "Category" }
        static var CategoryEN: FieldKey { "CategoryEN" }
        static var CategoryIT: FieldKey { "CategoryIT" }
        static var SubCategory: FieldKey { "SubCategory" }
        static var SubCategoryEN: FieldKey { "SubCategoryEN" }
        static var SubCategoryIT: FieldKey { "SubCategoryIT" }
        static var Brand: FieldKey { "Brand" }
        static var LifePhase: FieldKey { "LifePhase" }
        static var OnlineTitle: FieldKey { "OnlineTitle" }
        static var OnlineTitleEN: FieldKey { "OnlineTitleEN" }
        static var OnlineTitleIT: FieldKey { "OnlineTitleIT" }
        static var ProductDescriptionLong: FieldKey { "ProductDescriptionLong" }
        static var ProductDescriptionLongEN: FieldKey { "ProductDescriptionLongEN" }
        static var Chains: FieldKey { "Chains" }
        static var HeightMasterBox: FieldKey { "HeightMasterBox" }
        static var WidthMasterBox: FieldKey { "WidthMasterBox" }
        static var LongMasterBox: FieldKey { "LongMasterBox" }
        static var NetWeightMasterBox: FieldKey { "NetWeightMasterBox" }
        static var GrossWeightMasterBox: FieldKey { "GrossWeightMasterBox" }
        static var HeightInnerBox: FieldKey { "HeightInnerBox" }
        static var WidthInnerBox: FieldKey { "WidthInnerBox" }
        static var LongInnerBox: FieldKey { "LongInnerBox" }
        static var NetWeightInnerBox: FieldKey { "NetWeightInnerBox" }
        static var GrossWeightInnerBox: FieldKey { "GrossWeightInnerBox" }
        static var HeightArticle: FieldKey { "HeightArticle" }
        static var WidthArticle: FieldKey { "WidthArticle" }
        static var LongArticle: FieldKey { "LongArticle" }
        static var NetWeightArticle: FieldKey { "NetWeightArticle" }
        static var GrossWeightArticle: FieldKey { "GrossWeightArticle" }
        static var EAN13Article: FieldKey { "EAN13Article" }
        static var ProductDescriptionEN: FieldKey { "ProductDescriptionEN" }
        static var ProductDescriptionIT: FieldKey { "ProductDescriptionIT" }
        static var PSCategory: FieldKey { "PSCategory" }
        static var PSSubCategory: FieldKey { "PSSubCategory" }
        static var PSCategoryEN: FieldKey { "PSCategoryEN" }
        static var PSSubCategoryEN: FieldKey { "PSSubCategoryEN" }
        static var ProductLine: FieldKey { "ProductLine" }
        static var GHSCode: FieldKey { "GHSCode" }
        static var CountryOfOrigin: FieldKey { "CountryOfOrigin" }
        static var ProductStatus: FieldKey { "ProductStatus" }
        static var Price: FieldKey { "Price" }
        static var AvailableStock: FieldKey { "AvailableStock" }
        static var Files: FieldKey { "Files" }
    }

    init() { }

    init(id: UUID? = nil, IDArticle: String?, CodArticle: String, Description: String?, Category: String?, CategoryEN: String?, CategoryIT: String?, SubCategory: String?, SubCategoryEN: String?, SubCategoryIT: String?, Brand: String?, LifePhase: String?, OnlineTitle: String?, OnlineTitleEN: String?, OnlineTitleIT: String?, ProductDescriptionLong: String?, ProductDescriptionLongEN: String?, Chains: String?, HeightMasterBox: Double?, WidthMasterBox: Double?, LongMasterBox: Double?, NetWeightMasterBox: Double?, GrossWeightMasterBox: Double?, HeightInnerBox: Double?, WidthInnerBox: Double?, LongInnerBox: Double?, NetWeightInnerBox: Double?, GrossWeightInnerBox: Double?, HeightArticle: Double?, WidthArticle: Double?, LongArticle: Double?, NetWeightArticle: Double?, GrossWeightArticle: Double?, EAN13Article: String?, ProductDescriptionEN: String?, ProductDescriptionIT: String?, PSCategory: String?, PSSubCategory: String?, PSCategoryEN: String?, PSSubCategoryEN: String?, ProductLine: String?, GHSCode: String?, CountryOfOrigin: String?, ProductStatus: String?, Price: Int?, AvailableStock: Int?, Files: [File]?) {
        self.id = id
        self.IDArticle = IDArticle
        self.CodArticle = CodArticle
        self.Description = Description
        self.Category = Category
        self.CategoryEN = CategoryEN
        self.CategoryIT = CategoryIT
        self.SubCategory = SubCategory
        self.SubCategoryEN = SubCategoryEN
        self.SubCategoryIT = SubCategoryIT
        self.Brand = Brand
        self.LifePhase = LifePhase
        self.OnlineTitle = OnlineTitle
        self.OnlineTitleEN = OnlineTitleEN
        self.OnlineTitleIT = OnlineTitleIT
        self.ProductDescriptionLong = ProductDescriptionLong
        self.ProductDescriptionLongEN = ProductDescriptionLongEN
        self.Chains = Chains
        self.HeightMasterBox = HeightMasterBox
        self.WidthMasterBox = WidthMasterBox
        self.LongMasterBox = LongMasterBox
        self.NetWeightMasterBox = NetWeightMasterBox
        self.GrossWeightMasterBox = GrossWeightMasterBox
        self.HeightInnerBox = HeightInnerBox
        self.WidthInnerBox = WidthInnerBox
        self.LongInnerBox = LongInnerBox
        self.NetWeightInnerBox = NetWeightInnerBox
        self.GrossWeightInnerBox = GrossWeightInnerBox
        self.HeightArticle = HeightArticle
        self.WidthArticle = WidthArticle
        self.LongArticle = LongArticle
        self.NetWeightArticle = NetWeightArticle
        self.GrossWeightArticle = GrossWeightArticle
        self.EAN13Article = EAN13Article
        self.ProductDescriptionEN = ProductDescriptionEN
        self.ProductDescriptionIT = ProductDescriptionIT
        self.PSCategory = PSCategory
        self.PSSubCategory = PSSubCategory
        self.PSCategoryEN = PSCategoryEN
        self.PSSubCategoryEN = PSSubCategoryEN
        self.ProductLine = ProductLine
        self.GHSCode = GHSCode
        self.CountryOfOrigin = CountryOfOrigin
        self.ProductStatus = ProductStatus
        self.Price = Price
        self.AvailableStock = AvailableStock
        self.Files = Files
    }
}

struct File: Codable {
    let IDFile: String
    let Description: String
    let CodCategoryType: String
    let CategoryType: String
    let CodDocumentType: String
    let IDDocumentType: String
    let DocumentType: String
    let IDArticle: String
    let URL: String
    let PublicURL: String
    let DocumentDescription: String?

    enum CodingKeys: String, CodingKey {
        case IDFile, Description, CodCategoryType, CategoryType, CodDocumentType, IDDocumentType, DocumentType, IDArticle, URL, PublicURL, DocumentDescription
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        IDFile = try container.decode(String.self, forKey: .IDFile)
        Description = try container.decode(String.self, forKey: .Description)
        CodCategoryType = try container.decodeStringOrNumber(forKey: .CodCategoryType)
        CategoryType = try container.decode(String.self, forKey: .CategoryType)
        CodDocumentType = try container.decode(String.self, forKey: .CodDocumentType)
        IDDocumentType = try container.decode(String.self, forKey: .IDDocumentType)
        DocumentType = try container.decode(String.self, forKey: .DocumentType)
        IDArticle = try container.decode(String.self, forKey: .IDArticle)
        URL = try container.decode(String.self, forKey: .URL)
        PublicURL = try container.decode(String.self, forKey: .PublicURL)
        DocumentDescription = try container.decodeIfPresent(String.self, forKey: .DocumentDescription)
    }
}

extension KeyedDecodingContainer {
    func decodeStringOrNumber(forKey key: KeyedDecodingContainer<K>.Key) throws -> String {
        if let stringValue = try? self.decode(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? self.decode(Int.self, forKey: key) {
            return String(intValue)
        }
        if let doubleValue = try? self.decode(Double.self, forKey: key) {
            return String(doubleValue)
        }
        throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: [key], debugDescription: "Expected to decode String or Number but found another type instead."))
    }
}

extension ProductMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Product.schema)
            .id()
            .field(Product.FieldKeys.IDArticle, .string)
            .field(Product.FieldKeys.CodArticle, .string, .required)
            .field(Product.FieldKeys.Description, .string)
            .field(Product.FieldKeys.Category, .string)
            .field(Product.FieldKeys.CategoryEN, .string)
            .field(Product.FieldKeys.CategoryIT, .string)
            .field(Product.FieldKeys.SubCategory, .string)
            .field(Product.FieldKeys.SubCategoryEN, .string)
            .field(Product.FieldKeys.SubCategoryIT, .string)
            .field(Product.FieldKeys.Brand, .string)
            .field(Product.FieldKeys.LifePhase, .string)
            .field(Product.FieldKeys.OnlineTitle, .string)
            .field(Product.FieldKeys.OnlineTitleEN, .string)
            .field(Product.FieldKeys.OnlineTitleIT, .string)
            .field(Product.FieldKeys.ProductDescriptionLong, .string)
            .field(Product.FieldKeys.ProductDescriptionLongEN, .string)
            .field(Product.FieldKeys.Chains, .string)
            .field(Product.FieldKeys.HeightMasterBox, .double)
            .field(Product.FieldKeys.WidthMasterBox, .double)
            .field(Product.FieldKeys.LongMasterBox, .double)
            .field(Product.FieldKeys.NetWeightMasterBox, .double)
            .field(Product.FieldKeys.GrossWeightMasterBox, .double)
            .field(Product.FieldKeys.HeightInnerBox, .double)
            .field(Product.FieldKeys.WidthInnerBox, .double)
            .field(Product.FieldKeys.LongInnerBox, .double)
            .field(Product.FieldKeys.NetWeightInnerBox, .double)
            .field(Product.FieldKeys.GrossWeightInnerBox, .double)
            .field(Product.FieldKeys.HeightArticle, .double)
            .field(Product.FieldKeys.WidthArticle, .double)
            .field(Product.FieldKeys.LongArticle, .double)
            .field(Product.FieldKeys.NetWeightArticle, .double)
            .field(Product.FieldKeys.GrossWeightArticle, .double)
            .field(Product.FieldKeys.EAN13Article, .string)
            .field(Product.FieldKeys.ProductDescriptionEN, .string)
            .field(Product.FieldKeys.ProductDescriptionIT, .string)
            .field(Product.FieldKeys.PSCategory, .string)
            .field(Product.FieldKeys.PSSubCategory, .string)
            .field(Product.FieldKeys.PSCategoryEN, .string)
            .field(Product.FieldKeys.PSSubCategoryEN, .string)
            .field(Product.FieldKeys.ProductLine, .string)
            .field(Product.FieldKeys.GHSCode, .string)
            .field(Product.FieldKeys.CountryOfOrigin, .string)
            .field(Product.FieldKeys.ProductStatus, .string)
            .field(Product.FieldKeys.Price, .int)
            .field(Product.FieldKeys.AvailableStock, .int)
            .field(Product.FieldKeys.Files, .array(of: .json))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Product.schema).delete()
    }
}

extension Product: Mergeable {
    func merge(from other: Product) -> Product {
        var merged = self
        merged.IDArticle = other.IDArticle ?? self.IDArticle
        merged.CodArticle = other.CodArticle ?? self.CodArticle
        merged.Description = other.Description ?? self.Description
        merged.Category = other.Category ?? self.Category
        merged.CategoryEN = other.CategoryEN ?? self.CategoryEN
        merged.CategoryIT = other.CategoryIT ?? self.CategoryIT
        merged.SubCategory = other.SubCategory ?? self.SubCategory
        merged.SubCategoryEN = other.SubCategoryEN ?? self.SubCategoryEN
        merged.SubCategoryIT = other.SubCategoryIT ?? self.SubCategoryIT
        merged.Brand = other.Brand ?? self.Brand
        merged.LifePhase = other.LifePhase ?? self.LifePhase
        merged.OnlineTitle = other.OnlineTitle ?? self.OnlineTitle
        merged.OnlineTitleEN = other.OnlineTitleEN ?? self.OnlineTitleEN
        merged.OnlineTitleIT = other.OnlineTitleIT ?? self.OnlineTitleIT
        merged.ProductDescriptionLong = other.ProductDescriptionLong ?? self.ProductDescriptionLong
        merged.ProductDescriptionLongEN = other.ProductDescriptionLongEN ?? self.ProductDescriptionLongEN
        merged.Chains = other.Chains ?? self.Chains
        merged.HeightMasterBox = other.HeightMasterBox ?? self.HeightMasterBox
        merged.WidthMasterBox = other.WidthMasterBox ?? self.WidthMasterBox
        merged.LongMasterBox = other.LongMasterBox ?? self.LongMasterBox
        merged.NetWeightMasterBox = other.NetWeightMasterBox ?? self.NetWeightMasterBox
        merged.GrossWeightMasterBox = other.GrossWeightMasterBox ?? self.GrossWeightMasterBox
        merged.HeightInnerBox = other.HeightInnerBox ?? self.HeightInnerBox
        merged.WidthInnerBox = other.WidthInnerBox ?? self.WidthInnerBox
        merged.LongInnerBox = other.LongInnerBox ?? self.LongInnerBox
        merged.NetWeightInnerBox = other.NetWeightInnerBox ?? self.NetWeightInnerBox
        merged.GrossWeightInnerBox = other.GrossWeightInnerBox ?? self.GrossWeightInnerBox
        merged.HeightArticle = other.HeightArticle ?? self.HeightArticle
        merged.WidthArticle = other.WidthArticle ?? self.WidthArticle
        merged.LongArticle = other.LongArticle ?? self.LongArticle
        merged.NetWeightArticle = other.NetWeightArticle ?? self.NetWeightArticle
        merged.GrossWeightArticle = other.GrossWeightArticle ?? self.GrossWeightArticle
        merged.EAN13Article = other.EAN13Article ?? self.EAN13Article
        merged.ProductDescriptionEN = other.ProductDescriptionEN ?? self.ProductDescriptionEN
        merged.ProductDescriptionIT = other.ProductDescriptionIT ?? self.ProductDescriptionIT
        merged.PSCategory = other.PSCategory ?? self.PSCategory
        merged.PSSubCategory = other.PSSubCategory ?? self.PSSubCategory
        merged.PSCategoryEN = other.PSCategoryEN ?? self.PSCategoryEN
        merged.PSSubCategoryEN = other.PSSubCategoryEN ?? self.PSSubCategoryEN
        merged.ProductLine = other.ProductLine ?? self.ProductLine
        merged.GHSCode = other.GHSCode ?? self.GHSCode
        merged.CountryOfOrigin = other.CountryOfOrigin ?? self.CountryOfOrigin
        merged.ProductStatus = other.ProductStatus ?? self.ProductStatus
        merged.Price = other.Price ?? self.Price
        merged.AvailableStock = other.AvailableStock ?? self.AvailableStock
        merged.Files = other.Files ?? self.Files
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        return merged
    }
}

extension Product {
    func isEqualTo(_ other: Product) -> Bool {
        return self.IDArticle == other.IDArticle &&
            self.CodArticle == other.CodArticle &&
            self.Description == other.Description &&
            // Add other fields that you consider for comparison
            self.Price == other.Price &&
            self.AvailableStock == other.AvailableStock
    }
}
