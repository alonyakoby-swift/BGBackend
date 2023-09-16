//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Fluent
import Vapor
import Leaf

func routes(_ app: Application) throws {
    let routes: [RouteCollection] = [
        CategoryController(path: "categories"),
        BrandController(path: "brands"),
        KPIController(path: "kpi"),
        CustomerController(path: "customers"),
        VendorController(path: "vendors"),
        FilesController(path: "files"),
        UserController(path: "users"),
        TeamController(path: "teams"),
        CollectionController(path: "collections"),
        ProductController(path: "products")
    ]
    
    app.get("status") { req async -> String in
        "Status Online!"
    }
    
    do {
        try routes.forEach { try app.register(collection: $0) }
    } catch {
        print("Routes couldn't be initialized!")
    }
}

//
//    let mailConfig = EmailConfiguration(hostname: "smtp.gmail.com",
//                                        email: "alon.yakoby@gmail.com",
//                                        password: "mgdwoxhkusodvsjz")
//



