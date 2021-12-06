import Fluent
import FluentMySQLDriver
import Leaf
import CiamSwiftKit
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // 这里是 Session 认证中间件
    app.middleware.use(app.sessions.middleware)
    
    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .mysql)

    // 这里需要注意先后顺序
    app.migrations.add(CreateUser())
    app.migrations.add(CreateTodo())

    app.views.use(.leaf)

    // MARK: App Config
    app.config = .environment
    
    app.ciam.credentials = .init(clientId: app.config.clientId, clientSecret: app.config.clientSecret, tokenUri: "\(app.config.userDomain)/oauth2/token")
    app.ciam.auth.configuration = .init(scopes: [.openid],
                                        userDomain: app.config.userDomain,
                                        redirectUri: app.config.redirectUri,
                                        logoutRedirectUrl: app.config.logoutRedirectUrl)

    // register routes
    try routes(app)
}
