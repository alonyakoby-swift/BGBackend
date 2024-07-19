import Vapor
import Fluent
import Combine

/// Controller for managing product operations.
final class ProductController: RouteCollection {
    
    /// Repository for handling CRUD operations on `Product` entities.
    let repository: StandardControllerRepository<Product>
    
    /// Gateway for interacting with external data sources.
    let dataSourceGateway = DataSourceGateway()
    
    var cancellables = Set<AnyCancellable>()
    
    /// Initializes a new instance of `ProductController`.
    /// - Parameter path: The base path for API routes.
    init(path: String) {
        self.repository = StandardControllerRepository<Product>(path: path)
        authenticate()
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
        
        route.get("gateway", "fetchProducts", use: fetchProducts)
        route.get("gateway", "fetch", ":itemCode", use: fetchProductByItemCode)
        route.get("gateway", "syncDatabase", "batch", use: syncDatabaseBatched)
        route.get("gateway", "syncDatabase", use: syncDatabase)
        route.get("gateway", "listBrands", use: listBrands)
    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }

    /// Performs authentication with the external data source.
    private func authenticate() {
        dataSourceGateway.authenticate(username: username, password: password)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Authenticated successfully")
                    print("Access Token: \(self.dataSourceGateway.accessToken ?? "No Token")")
                case .failure(let error):
                    print("Failed to authenticate: \(error)")
                }
            }, receiveValue: { })
            .store(in: &cancellables)
    }

    /// Fetches a page of products.
    /// - Parameter req: The incoming `Request`.
    /// - Returns: A future that resolves to a `Page` of `Product`.
    func fetchProducts(req: Request) throws -> EventLoopFuture<Page<Product>> {
        let pageRequest = try req.query.decode(PageRequest.self)
        print("Page: \(pageRequest.page), Per Page: \(pageRequest.per)")
        return try repository.paginate(req: req)
    }

    /// Fetches a product by its item code.
    /// - Parameter req: The incoming `Request`.
    /// - Returns: A future that resolves to a `Product`.
    func fetchProductByItemCode(req: Request) -> EventLoopFuture<Product> {
        let promise = req.eventLoop.makePromise(of: Product.self)
        guard let itemCode = req.parameters.get("itemCode") else {
            promise.fail(Abort(.badRequest, reason: "Missing item code"))
            return promise.futureResult
        }

        fetchArticleByItemCode(itemCode: itemCode, promise: promise, retryCount: 1)
        
        return promise.futureResult
    }
    
    /// Helper function to fetch an article by its item code.
    /// - Parameters:
    ///   - itemCode: The item code of the product.
    ///   - promise: The promise to fulfill with the fetched product.
    ///   - retryCount: The number of retry attempts remaining.
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

    /// Synchronizes the local database with remote products.
    /// - Parameter req: The incoming `Request`.
    /// - Returns: A future that resolves to `HTTPStatus`.
    func syncDatabaseBatched(req: Request) -> EventLoopFuture<HTTPStatus> {
        return syncDatabaseBatch(req: req, page: 1, perPage: 250)
    }

    
    /// Synchronizes the local database with remote products.
    /// - Parameter req: The incoming `Request`.
    /// - Returns: A future that resolves to `HTTPStatus`.
    func syncDatabase(req: Request) -> EventLoopFuture<HTTPStatus> {
        return syncDatabaseFull(req: req)
    }
    
    /// Synchronizes the local database with remote products in batches.
    /// - Parameters:
    ///   - req: The incoming `Request`.
    ///   - page: The current page number.
    ///   - perPage: The number of products per page.
    /// - Returns: A future that resolves to `HTTPStatus`.
    private func syncDatabaseBatch(req: Request, page: Int, perPage: Int) -> EventLoopFuture<HTTPStatus> {
        let promise = req.eventLoop.makePromise(of: HTTPStatus.self)

        // Fetch products list for the current batch
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
                
                // Load the local products from the database
                Product.query(on: req.db).all().flatMap { localProducts in
                    print("Fetched local products: \(localProducts.count) items")
                    
                    // Create a dictionary for quick lookup by item code
                    let localProductsDict = Dictionary(localProducts.map { ($0.CodArticle, $0) }, uniquingKeysWith: { first, _ in first })

                    // Find new or updated products
                    let newOrUpdatedProducts = remoteProducts.filter { remoteProduct in
                        if let localProduct = localProductsDict[remoteProduct.CodArticle] {
                            // Compare local and remote product details, if necessary
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

                    // Create the new or updated products in the database
                    let createOrUpdateFutures = newOrUpdatedProducts.map { product in
                        product.save(on: req.db).flatMap { _ -> EventLoopFuture<Void> in
                            // Create Translation objects for each language
                            let translations = Language.allCases.map { language in
                                let translation = Translation(
                                    itemCode: product.CodArticle,
                                    base: product.Description ?? "",
                                    language: language,
                                    rating: 0,
                                    translation: "",
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

                    // Wait for all creations to complete
                    return EventLoopFuture.andAllComplete(createOrUpdateFutures, on: req.eventLoop).flatMap {
                        if page < productListResponse.last_page ?? 0 {
                            // Continue to the next page
                            return self.syncDatabaseBatch(req: req, page: page + 1, perPage: perPage)
                        } else {
                            // All pages processed
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


    /// Synchronizes the local database with remote products in batches.
    /// - Parameters:
    ///   - req: The incoming `Request`.
    ///   - page: The current page number.
    ///   - perPage: The number of products per page.
    /// - Returns: A future that resolves to `HTTPStatus`.
    private func syncDatabaseFull(req: Request) -> EventLoopFuture<HTTPStatus> {
            let promise = req.eventLoop.makePromise(of: HTTPStatus.self)

            // Fetch products list for the current batch
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
                    
                    // Load the local products from the database
                    Product.query(on: req.db).all().flatMap { localProducts in
                        print("Fetched local products: \(localProducts.count) items")
                        
                        // Create a dictionary for quick lookup by item code
                        let localProductsDict = Dictionary(localProducts.map { ($0.CodArticle, $0) }, uniquingKeysWith: { first, _ in first })

                        // Find new or updated products
                        let newOrUpdatedProducts = remoteProducts.filter { remoteProduct in
                            if let localProduct = localProductsDict[remoteProduct.CodArticle] {
                                // Compare local and remote product details, if necessary
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

                        // Create the new or updated products in the database
                        let createOrUpdateFutures = newOrUpdatedProducts.map { product in
                            product.save(on: req.db).flatMap { _ -> EventLoopFuture<Void> in
                                // Create Translation objects for each language
                                let translations = Language.allCases.map { language in
                                    let translation = Translation(
                                        itemCode: product.CodArticle,
                                        base: product.Description ?? "",
                                        language: language,
                                        rating: 0,
                                        translation: "",
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

                        // Wait for all creations to complete
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


    
    /// Lists all unique brands of products.
    /// - Parameter req: The incoming `Request`.
    /// - Returns: A future that resolves to an array of unique brand names.
    func listBrands(req: Request) -> EventLoopFuture<[String]> {  
        return Product.query(on: req.db)
            .unique().field(\.$Brand)
            .all()
            .map { products in
                return products.compactMap { $0.Brand }
                    .removingDuplicates()
            }
    }
}

extension Array where Element == String {
    /// Removes duplicate elements from the array.
    /// - Returns: An array containing only unique elements.
    func removingDuplicates() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

let username: String = "alon.yakoby@gmail.com"
let password: String = "Bergner@Yakobi"
let client_secret: String = "SjdmevjDnsE0LRAHFBMJK1wkOO9Pav8Ki19DGkr4"
