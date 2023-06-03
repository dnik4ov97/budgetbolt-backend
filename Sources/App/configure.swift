import Vapor
import Fluent
import FluentMongoDriver

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.databases.use(.mongo(connectionString: "mongodb+srv://dnikiforov:XdG9KCJyKa3E9rxy@users1.ocuefjd.mongodb.net/user_names"), as: .mongo)
    
    app.migrations.add(CreateUserNames())
        
//    try app.autoMigrate().wait()
    
    // register routes
    try routes(app)
}
