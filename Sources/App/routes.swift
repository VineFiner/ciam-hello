import Fluent
import Vapor

func routes(_ app: Application) throws {
    
    // 测试路由
    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.register(collection: TodoController())
    try app.register(collection: DirectoryManagerController())
    try app.register(collection: WebsiteController())
}
