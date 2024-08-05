//
//
//  Copyright © 2023.
//  Alon Yakobichvili
//  All rights reserved.
//

import App
import Vapor
import Firebase

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

// Initialize Firebase
FirebaseConfiguration.configure()

try configure(app)
try app.run()
