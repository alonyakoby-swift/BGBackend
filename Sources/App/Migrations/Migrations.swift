//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Fluent

let app_migrations: [Migration] = [
    TagMigration(),
    FileMigration(),
    BrandMigration(),
    CategoryMigration(),
    CollectionMigration(),
    KPIMigration(),
    ProductMigration(),
    VendorMigration(),
    BoardMigration(),
    CustomerMigration(),
    OrderProductMigration(),
    OrderTicketMigration(),
    TeamMigration(),
    UserMigration(),
    TokenMigration(),
    UserVerificationTokenMigration(),
    UserTeamPivotMigration(),
]

struct TagMigration { }
struct FileMigration { }
struct BrandMigration { }
struct CategoryMigration { }
struct CollectionMigration { }
struct KPIMigration { }
struct ProductMigration { }
struct VendorMigration { }
struct BoardMigration { }
struct CustomerMigration { }
struct OrderProductMigration { }
struct OrderTicketMigration { }
struct TeamMigration { }
struct UserMigration { }
struct TokenMigration { }
struct UserVerificationTokenMigration { }
struct UserTeamPivotMigration { }
