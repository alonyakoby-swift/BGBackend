//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import Fluent

let app_migrations: [Migration] = [
    UserMigration(),
    UserVerificationTokenMigration(),
    ProductMigration(),
    TokenMigration(),
    ExceptionMigration(),
    LogMigration()
]
struct UserMigration { }
struct UserVerificationTokenMigration { }
struct ProductMigration { }
struct TokenMigration { }
struct TranslationMigration { }
struct ExceptionMigration { }
struct LogMigration { }
