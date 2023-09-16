//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Foundation
import Vapor
import Fluent

final class File: Model, Content, Codable {
    static let schema = "file"

    @ID(custom: FieldKeys.id) var id: UUID?
    @Field(key: FieldKeys.fileName) var fileName: String
    @Field(key: FieldKeys.fileType) var fileType: FileType
    @Field(key: FieldKeys.fileSizeKB) var fileSizeKB: Int
    @Field(key: FieldKeys.downloadURL) var downloadURL: String
    @OptionalParent(key: FieldKeys.collection) var collection: Collection?

    struct FieldKeys {
        static var id: FieldKey { "id" }
        static var fileName: FieldKey { "fileName" }
        static var fileType: FieldKey { "fileType" }
        static var fileSizeKB: FieldKey { "fileSizeKB" }
        static var downloadURL: FieldKey { "downloadURL" }
        static var collection: FieldKey { "collection" }
    }

    init() { }
    init(id: UUID? = nil, fileName: String, fileType: FileType, fileSizeKB: Int, downloadURL: String, collectionID: Collection.IDValue?) {
        self.id = id
        self.fileName = fileName
        self.fileType = fileType
        self.fileSizeKB = fileSizeKB
        self.downloadURL = downloadURL
        self.$collection.id = collectionID
    }
}

extension FileMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(File.schema)
            .field(File.FieldKeys.id, .uuid, .identifier(auto: true))
            .field(File.FieldKeys.fileName, .string, .required)
            .field(File.FieldKeys.fileType, .string, .required)
            .field(File.FieldKeys.fileSizeKB, .int, .required)
            .field(File.FieldKeys.downloadURL, .string, .required)
            .field(File.FieldKeys.collection, .uuid, .references("collection", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(File.schema).delete()
    }
}
