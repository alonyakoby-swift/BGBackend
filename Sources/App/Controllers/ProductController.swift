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
    
    init(path: String) {
        self.repository = StandardControllerRepository<Product>(path: path)
    }

    func setupRoutes(on app: RoutesBuilder) throws {
        let route = app.grouped(PathComponent(stringLiteral: repository.path))
        
        route.post(use: repository.create)
        route.post("batch", use: repository.createBatch)

        route.get(use: repository.index)
        route.delete(":id", use: repository.deleteID)

        route.patch(":id", use: repository.updateID)
        route.patch("batch", use: repository.updateBatch)
        
        route.get("gateway", "fetchProducts", use: fetchProducts)

    }

    func boot(routes: RoutesBuilder) throws {
        try setupRoutes(on: routes)
    }

    // Func addData
    
    /* will pass an array of items
     
     {
       "product": {
         "cod_article": "01481",
         "product_name": "SET 4 PCS  MEAT KNIFE 11.5CM BISTRO 3CLAVELES",
         "customer_description": "SET 4 PCS  MEAT KNIFE 11.5CM BISTRO 3CLAVELES"
       }
     }

     parse that into products and save
     */
    //
    
    func fetchProducts(req: Request) throws -> EventLoopFuture<Page<Product>> {
        let pageRequest = try req.query.decode(PageRequest.self)
        print("Page: \(pageRequest.page), Per Page: \(pageRequest.per)")
        return try repository.paginate(req: req)
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

var globalTranslationManager: TranslationManager?
