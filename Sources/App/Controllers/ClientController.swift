import Vapor
import Fluent

struct ProductRequest: Content {
    let code: String
    let name: String
    let description: String
}

struct SellingPointRequest: Content {
    let code: String
    let selling_point: String
}

struct ProductCodeRequest: Content {
    let itemCode: String
}

struct ProductResponse: Content {
    let id: UUID?
    let code: String?
    let name: String?
    let description: String
    let translations: [TranslationDTO]
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

struct TranslationDTO: Content {
    let language: String
    let translation: String
    let status: String
    let rating: Int
    let verification: String
}

final class ClientController: RouteCollection {
    let path: String
    let translation_manager = globalTranslationManager
    
    init(path: String) {
        self.path = path
    }
    
    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }
    
    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: path))
        route.post("product", use: createProduct)
        route.post("product", "code", use: getProductByCode)
    }
    
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
            .filter(\.$code == codeRequest.itemCode)
            .with(\.$translations)
            .first() else {
            throw Abort(.notFound, reason: "Product with code \(codeRequest.itemCode) not found")
        }

        return ProductResponse(product: product)
    }
}
