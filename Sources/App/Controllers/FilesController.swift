//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//
  

import Vapor

final class FilesController: RouteCollection {
    let repository: StandardControllerRepository<File>
    
    init(path: String) {
        self.repository = StandardControllerRepository<File>(path: path)
    }
    
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        route.post(use: repository.create)
        route.post("batch", use: repository.createBatch)

        route.get(use: repository.index)
        route.get(":id", use: repository.getbyID)
        route.delete(":id", use: repository.deleteID)
        
        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
}

extension File: Mergeable {
    func merge(from other: File) -> File {
        let merged = self
        merged.downloadURL = other.downloadURL
        merged.fileName = other.fileName
        merged.fileType = other.fileType
        merged.fileSizeKB = other.fileSizeKB
        return merged
    }
}
