import Vapor
import Fluent
#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineFoundation
#endif

final class ProductController: RouteCollection {
    let repository: StandardControllerRepository<Product>
    let dataSourceGateway = DataSourceGateway()
    var cancellables = Set<AnyCancellable>()
    
    init(path: String) {
        self.repository = StandardControllerRepository<Product>(path: path)
        authenticate()
    }

    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        
        route.post(use: repository.create)
        route.post("batch", use: repository.createBatch)

        route.get(use: index)
        route.get(":id", use: getItemByIDWithTranslations)
        route.delete(":id", use: repository.deleteID)

        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
        
        route.get("gateway", "fetchProducts", use: fetchProducts)
        route.get("gateway", "fetch", ":itemCode", use: fetchProductByItemCode)
        route.get("gateway", "syncDatabase", "batch", use: syncDatabaseBatched)
        route.get("gateway", "syncDatabase", use: syncDatabase)
        route.get("gateway", "listBrands", use: listBrands)
        
        route.get("searchbyItemCode", ":itemCode", use: searchByItemCode)
        route.get(":id", "format", use: formatProductDescription)
        
        route.get("search", use: search)

    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }

    private func authenticate() {
        dataSourceGateway.authenticate(username: username, password: password)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Authenticated successfully")
                case .failure(let error):
                    print("Failed to authenticate: \(error)")
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    func fetchProducts(req: Request) throws -> EventLoopFuture<Page<Product>> {
        let pageRequest = try req.query.decode(PageRequest.self)
        print("Page: \(pageRequest.page), Per Page: \(pageRequest.per)")
        return try repository.paginate(req: req)
    }

    func fetchProductByItemCode(req: Request) -> EventLoopFuture<Product> {
        let promise = req.eventLoop.makePromise(of: Product.self)
        guard let itemCode = req.parameters.get("itemCode") else {
            promise.fail(Abort(.badRequest, reason: "Missing item code"))
            return promise.futureResult
        }

        fetchArticleByItemCode(itemCode: itemCode, promise: promise, retryCount: 1)
        
        return promise.futureResult
    }
    
    private func fetchArticleByItemCode(itemCode: String, promise: EventLoopPromise<Product>, retryCount: Int) {
        dataSourceGateway.fetchProductCode(by: itemCode)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching product by item code: \(error)")
                    if retryCount > 0, case URLError.userAuthenticationRequired = error {
                        self.authenticate()
                        self.fetchArticleByItemCode(itemCode: itemCode, promise: promise, retryCount: retryCount - 1)
                    } else {
                        promise.fail(error)
                    }
                }
            }, receiveValue: { product in
                print("Fetched product: \(product)")
                promise.succeed(product)
            })
            .store(in: &cancellables)
    }

    func syncDatabaseBatched(req: Request) -> EventLoopFuture<HTTPStatus> {
        return syncDatabaseBatch(req: req, page: 1, perPage: 250)
    }

    func syncDatabase(req: Request) -> EventLoopFuture<HTTPStatus> {
        return syncDatabaseFull(req: req)
    }
    
    private func syncDatabaseBatch(req: Request, page: Int, perPage: Int) -> EventLoopFuture<HTTPStatus> {
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)

        dataSourceGateway.fetchProductsList(page: page, perPage: perPage)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    promise.fail(error)
                }
            }, receiveValue: { productListResponse in
                let remoteProducts = productListResponse.data
                print("Fetched remote products batch: \(remoteProducts.count) items from page \(page)")
                
                Product.query(on: req.db).all().flatMap { localProducts in
                    print("Fetched local products: \(localProducts.count) items")
                    
                    let localProductsDict = Dictionary(localProducts.map { ($0.CodArticle, $0) }, uniquingKeysWith: { first, _ in first })

                    let newOrUpdatedProducts = remoteProducts.filter { remoteProduct in
                        if let localProduct = localProductsDict[remoteProduct.CodArticle] {
                            let isEqual = localProduct.isEqualTo(remoteProduct)
                            if !isEqual {
                                print("Product updated: \(remoteProduct.CodArticle)")
                            }
                            return !isEqual
                        }
                        print("New product: \(remoteProduct.CodArticle)")
                        return true
                    }

                    print("New or updated products: \(newOrUpdatedProducts.count) items")

                    let createOrUpdateFutures = newOrUpdatedProducts.map { product in
                        product.save(on: req.db).flatMap { _ -> EventLoopFuture<Void> in
                            let translations = Language.allCases.map { language in
                                let translation = Translation(
                                    product: product.id!,
                                    itemCode: product.CodArticle,
                                    base: product.Description ?? "",
                                    language: language,
                                    rating: 0,
                                    translation: "",
                                    verification: "",
                                    status: .pending
                                )
                                return translation.save(on: req.db).map {
                                }.flatMapError { error in
                                    print("Error saving translation for product: \(product.CodArticle) in language: \(language.rawValue) - \(error)")
                                    return req.eventLoop.makeSucceededFuture(())
                                }
                            }
                            return EventLoopFuture.andAllComplete(translations, on: req.eventLoop)
                        }.flatMapError { error in
                            print("Error saving product: \(product.CodArticle) - \(error)")
                            return req.eventLoop.makeSucceededFuture(())
                        }
                    }

                    return EventLoopFuture.andAllComplete(createOrUpdateFutures, on: req.eventLoop).flatMap {
                        if page < productListResponse.last_page ?? 0 {
                            return self.syncDatabaseBatch(req: req, page: page + 1, perPage: perPage)
                        } else {
                            promise.succeed(.ok)
                            return promise.futureResult
                        }
                    }.flatMapError { error in
                        print("Error processing batch: \(error)")
                        return req.eventLoop.makeSucceededFuture(.internalServerError)
                    }
                }.flatMapError { error in
                    print("Error fetching local products: \(error)")
                    return req.eventLoop.makeSucceededFuture(.internalServerError)
                }
            })
            .store(in: &cancellables)

        return promise.futureResult
    }

    private func syncDatabaseFull(req: Request) -> EventLoopFuture<HTTPStatus> {
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)
        
        dataSourceGateway.fetchProductsList()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    promise.fail(error)
                }
            }, receiveValue: { productListResponse in
                let remoteProducts = productListResponse.data
                print("Fetched remote products batch: \(remoteProducts.count)")
                
                Product.query(on: req.db).all().flatMap { localProducts in
                    print("Fetched local products: \(localProducts.count) items")
                    
                    let localProductsDict = Dictionary(localProducts.map { ($0.CodArticle, $0) }, uniquingKeysWith: { first, _ in first })

                    let newOrUpdatedProducts = remoteProducts.filter { remoteProduct in
                        if let localProduct = localProductsDict[remoteProduct.CodArticle] {
                            let isEqual = localProduct.isEqualTo(remoteProduct)
                            if !isEqual {
                                print("Product updated: \(remoteProduct.CodArticle)")
                            }
                            return !isEqual
                        }
                        print("New product: \(remoteProduct.CodArticle)")
                        return true
                    }

                    print("New or updated products: \(newOrUpdatedProducts.count) items")

                    let createOrUpdateFutures = newOrUpdatedProducts.map { product in
                        product.save(on: req.db).flatMap { _ -> EventLoopFuture<Void> in
                            let translations = Language.allCases.map { language in
                                let translation = Translation(
                                    product: product.id!,
                                    itemCode: product.CodArticle,
                                    base: product.ProductDescriptionEN?.formattedText(with: global_exceptions) ?? "",
                                    language: language,
                                    rating: 0,
                                    translation: "",
                                    verification: "",
                                    status: .pending
                                )
                                return translation.save(on: req.db).map {
                                }.flatMapError { error in
                                    print("Error saving translation for product: \(product.CodArticle) in language: \(language.rawValue) - \(error)")
                                    return req.eventLoop.makeSucceededFuture(())
                                }
                            }
                            return EventLoopFuture.andAllComplete(translations, on: req.eventLoop)
                        }.flatMapError { error in
                            print("Error saving product: \(product.CodArticle) - \(error)")
                            return req.eventLoop.makeSucceededFuture(())
                        }
                    }

                    return EventLoopFuture.andAllComplete(createOrUpdateFutures, on: req.eventLoop).flatMap {
                        promise.succeed(.ok)
                        return promise.futureResult

                    }.flatMapError { error in
                        print("Error processing batch: \(error)")
                        return req.eventLoop.makeSucceededFuture(.internalServerError)
                    }
                }.flatMapError { error in
                    print("Error fetching local products: \(error)")
                    return req.eventLoop.makeSucceededFuture(.internalServerError)
                }
            })
            .store(in: &cancellables)

        return promise.futureResult
    }

    func listBrands(req: Request) -> EventLoopFuture<[String]> {
        return Product.query(on: req.db)
            .unique().field(\.$Brand)
            .all()
            .map { products in
                return products.compactMap { $0.Brand }
                    .removingDuplicates()
            }
    }

    func searchByItemCode(req: Request) -> EventLoopFuture<[Product]> {
        guard let itemCode = req.parameters.get("itemCode") else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Missing item code"))
        }

        return Product.query(on: req.db)
            .filter(\.$CodArticle == itemCode)
            .with(\.$translations)
            .all()
    }

    func getItemByIDWithTranslations(req: Request) -> EventLoopFuture<ProductWithTranslations> {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            return req.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "Missing product ID"))
        }

        return Product.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { product in
                product.$translations.load(on: req.db).map {
                    return ProductWithTranslations(product: product, translations: product.translations)
                }
            }
    }
    
    func formatProductDescription(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Missing product ID")
        }

        guard let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound)
        }

        if let manager = globalTranslationManager {
            await product.formatText(manager: manager)
        }
        return .ok
    }
    
    func search(req: Request) -> EventLoopFuture<[Product]> {
        var queryBuilder = Product.query(on: req.db)

        // Search query parameter
        if let searchString = req.query[String.self, at: "query"] {
            queryBuilder = queryBuilder.group(.or) { group in
                group.filter(\.$CodArticle ~~ searchString)
                group.filter(\.$Description ~~ searchString)
            }
        }

        // Brand filter
        if let brand = req.query[String.self, at: "brand"] {
            queryBuilder = queryBuilder.filter(\.$Brand == brand)
        }

        // Category filter
        if let category = req.query[String.self, at: "category"] {
            queryBuilder = queryBuilder.filter(\.$Category == category)
        }

        // Subcategory filter
        if let subcategory = req.query[String.self, at: "subcategory"] {
            queryBuilder = queryBuilder.filter(\.$SubCategory == subcategory)
        }

        return queryBuilder.all()
    }

    // Example URL for testing:
    // /products/search?query=example&brand=BrandA&category=CategoryX&subcategory=SubCategoryY

    func index(req: Request) -> EventLoopFuture<Page<Product>> {
        return Product.query(on: req.db)
            .sort(\.$CodArticle, .ascending)
            .paginate(for: req)
    }

}

extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

struct ProductWithTranslations: Content {
    let product: Product
    let translations: [Translation]
}

let username: String = "alon.yakoby@gmail.com"
let password: String = "Bergner@Yakobi"
let client_secret: String = "SjdmevjDnsE0LRAHFBMJK1wkOO9Pav8Ki19DGkr4"

var globalTranslationManager: TranslationManager?
