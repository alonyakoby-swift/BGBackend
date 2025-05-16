// ClientController.swift

import Vapor
import Fluent

// MARK: - Request & Response Models

struct ProductRequest: Content {
    let code: String
    let name: String
    let description: String
}

struct SellingPointRequest: Content {
    let code: String
    let sellingPoint: String
}

struct ProductCodeRequest: Content {
    let code: String
}

struct BatchProductCodeRequest: Content {
    let codes: [String]
}

struct ProductResponse: Content {
    let id: UUID?
    let code: String?
    let name: String?
    let description: String
    let translations: [TranslationDTO]
}

struct BatchProductResponse: Content {
    let products: [ProductResponse]
}

struct SellingPointResponse: Content {
    let id: UUID?
    let code: String
    let sellingPoint: String
    let translations: [TranslationDTO]
}

struct BatchSellingPointResponse: Content {
    let sellingPoints: [SellingPointResponse]
}

struct TranslationDTO: Content {
    let language: String
    let translation: String
    let status: String
    let rating: Int
    let verification: String
}

extension ProductResponse {
    init(product: Product) {
        self.id = product.id
        self.code = product.code
        self.name = product.name
        self.description = product.description
        self.translations = product.translations.map {
            TranslationDTO(
                language: $0.language.rawValue,
                translation: $0.translation,
                status: $0.status?.rawValue ?? "",
                rating: $0.rating,
                verification: $0.verification ?? "N/A"
            )
        }
    }
}

extension SellingPointResponse {
    init(sellingPoint: SellingPoint) {
        self.id = sellingPoint.id
        self.code = sellingPoint.code
        self.sellingPoint = sellingPoint.sellingPoint
        self.translations = sellingPoint.translations.map {
            TranslationDTO(
                language: $0.language.rawValue,
                translation: $0.translation,
                status: $0.status?.rawValue ?? "",
                rating: $0.rating,
                verification: $0.verification ?? "N/A"
            )
        }
    }
}

// MARK: - ClientController

final class ClientController: RouteCollection {
    let path: String
    let translation_manager = globalTranslationManager

    init(path: String) {
        self.path = path
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
}

// MARK: - Route Setup

extension ClientController {
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: path))
        
        // 🔒 everything inside `secure` requires ʼAuthorization: Bearer <token>ʼ
        let secure = route.grouped(
            Token.authenticator(),   // looks up the token + logs user in
            Token.guardMiddleware()  // aborts with 401 if token missing/invalid
        )

        // Product Routes
        secure.post("product", use: createProduct)
        secure.post("product", "code", use: getProductByCode)
        secure.post("products", "batch", use: getProductsByBatchCodes)

        // Selling Point Routes
        secure.post("sp", use: createSellingPoint)
        secure.post("sp", "code", use: getSellingPointByCode)
        secure.post("sp", "batch", use: getSellingPointsByBatchCodes)
        
        // Exception Routes
        secure.post("exception", use: createException)
        secure.put("exception", use: updateException)
        secure.get("exception", ":id", use: getExceptionByID)
        secure.delete("exception", ":id", use: deleteException)

    }
}

// MARK: - Product Handlers

extension ClientController {
    func createProduct(req: Request) async throws -> Response {
        struct CreateProductResponse: Content {
            let createdProductID: UUID
        }

        let productReq = try req.content.decode(ProductRequest.self)

        let product = Product(
            code: productReq.code,
            name: productReq.name,
            description: productReq.description,
            created: Date(),
            modified: Date()
        )
        try await product.save(on: req.db)

        for language in Language.allCases where !language.isEnglish {
            let translation = Translation(
                product: try product.requireID(),
                sellingPoint: nil,
                base: product.description,
                language: language,
                rating: 0,
                translation: "",
                verification: nil,
                status: .pending
            )
            try await translation.save(on: req.db)
        }

        try await translation_manager?.processProductWorkflow(productID: try product.requireID())

        let response = CreateProductResponse(createdProductID: try product.requireID())
        return try await response.encodeResponse(status: .created, for: req)
    }

    func getProductByCode(req: Request) async throws -> ProductResponse {
        let codeRequest = try req.content.decode(ProductCodeRequest.self)

        guard let product = try await Product.query(on: req.db)
            .filter(\.$code == codeRequest.code)
            .with(\.$translations)
            .first() else {
            throw Abort(.notFound, reason: "Product with code \(codeRequest.code) not found")
        }

        return ProductResponse(product: product)
    }

    func getProductsByBatchCodes(req: Request) async throws -> BatchProductResponse {
        let batchRequest = try req.content.decode(BatchProductCodeRequest.self)

        let products = try await Product.query(on: req.db)
            .filter(\.$code ~~ batchRequest.codes)
            .with(\.$translations)
            .all()

        let productResponses = products.map { ProductResponse(product: $0) }
        return BatchProductResponse(products: productResponses)
    }
}

// MARK: - Selling Point Handlers

extension ClientController {
    func createSellingPoint(req: Request) async throws -> Response {
        struct CreateSellingPointResponse: Content {
            let createdSellingPointID: UUID
        }
        
        let spReq = try req.content.decode(SellingPointRequest.self)

        let sellingPoint = SellingPoint(
            code: spReq.code,
            sellingPoint: spReq.sellingPoint
        )
        try await sellingPoint.save(on: req.db)

        for language in Language.allCases where !language.isEnglish {
            let translation = Translation(
                product: nil,
                sellingPoint: try sellingPoint.requireID(),
                base: sellingPoint.sellingPoint,
                language: language,
                rating: 0,
                translation: "",
                verification: nil,
                status: .pending
            )
            try await translation.save(on: req.db)
        }

        try await translation_manager?.processSellingPointWorkflow(sellingPointID: try sellingPoint.requireID())

        let response = CreateSellingPointResponse(createdSellingPointID: try sellingPoint.requireID())
        return try await response.encodeResponse(status: .created, for: req)
    }

    func getSellingPointByCode(req: Request) async throws -> SellingPointResponse {
        let codeRequest = try req.content.decode(ProductCodeRequest.self)

        guard let sellingPoint = try await SellingPoint.query(on: req.db)
            .filter(\.$code == codeRequest.code)
            .with(\.$translations)
            .first() else {
            throw Abort(.notFound, reason: "SellingPoint with code \(codeRequest.code) not found")
        }

        return SellingPointResponse(sellingPoint: sellingPoint)
    }

    func getSellingPointsByBatchCodes(req: Request) async throws -> BatchSellingPointResponse {
        let batchRequest = try req.content.decode(BatchProductCodeRequest.self)

        let sellingPoints = try await SellingPoint.query(on: req.db)
            .filter(\.$code ~~ batchRequest.codes)
            .with(\.$translations)
            .all()

        let responses = sellingPoints.map { SellingPointResponse(sellingPoint: $0) }
        return BatchSellingPointResponse(sellingPoints: responses)
    }
}

// MARK: - Exception Handlers

extension ClientController {
    func createException(req: Request) async throws -> Response {
        let newException = try req.content.decode(Exception.self)
        try await newException.save(on: req.db)
        return try await newException.encodeResponse(status: .created, for: req)
    }

    func updateException(req: Request) async throws -> Response {
        let updatedException = try req.content.decode(Exception.self)
        guard let id = updatedException.id,
              let existing = try await Exception.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Exception not found")
        }

        existing.original = updatedException.original
        existing.replace = updatedException.replace
        try await existing.save(on: req.db)
        return try await existing.encodeResponse(for: req)
    }

    func getExceptionByID(req: Request) async throws -> Exception {
        guard let idString = req.parameters.get("id"),
              let uuid = UUID(uuidString: idString),
              let exception = try await Exception.find(uuid, on: req.db) else {
            throw Abort(.notFound, reason: "Exception not found")
        }
        return exception
    }

    func deleteException(req: Request) async throws -> HTTPStatus {
        guard let idString = req.parameters.get("id"),
              let uuid = UUID(uuidString: idString),
              let exception = try await Exception.find(uuid, on: req.db) else {
            throw Abort(.notFound, reason: "Exception not found")
        }

        try await exception.delete(on: req.db)
        return .noContent
    }
}
