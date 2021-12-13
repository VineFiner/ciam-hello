//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/12/5.
//

import Foundation
import Vapor
import JWTKit
import Fluent

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // 这里是验证器
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        
        // 默认页面
        authSessionsRoutes.get(use: indexHandler)

        // 登录
        authSessionsRoutes.get("login", use: loginHandler)
        authSessionsRoutes.get("logout", use: ciamAuthLogoutHandler)
        
        // Ciam 登录
        authSessionsRoutes.get("login", "siwa", "callback", use: ciamAuthCallbackHandler)
        
        // 这里是受保护路由
        let protectedRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        
        // 获取用户信息
        protectedRoutes.get("userinfo", use: userInfo)
    }
    
    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        let loggedUser = req.auth.get(User.self)
        let context = IndexContext(title: "Hello Ciam", loggedUser: loggedUser)
        return req.view.render("index.html", context)
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let context: LoginContext
        let siwaContext = try buildSIWAContext(on: req)
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true, siwaContext: siwaContext)
        } else {
            context = LoginContext(siwaContext: siwaContext)
        }
        return req.view.render("Ciam/login.html", context)
            .encodeResponse(for: req)
            .map { response in
                let expiryDate = Date().addingTimeInterval(300)
                let cookie = HTTPCookies.Value(string: siwaContext.state, expires: expiryDate, maxAge: 300, isHTTPOnly: true, sameSite: HTTPCookies.SameSitePolicy.none)
                response.cookies["SIWA_STATE"] = cookie
                return response
            }
    }
    
    // Get user information under CIAM Certification protection
    // http://127.0.0.1:8080/userinfo
    func userInfo(req: Request) async throws -> View {
        let user = try req.auth.require(User.self)
        return try await req.view.render("userInfo.html", ["title": "Hello Vapor!", "user": user.name])
    }
    
}

// MARK: Ciam
extension WebsiteController {
    
    func ciamAuthCallbackHandler(_ req: Request) async throws -> Response {
        
        let siwaData = try req.query.decode(CiamAuthorizationResponse.self)
        
        let result = try await req.ciamClient.fetchToken(code: siwaData.code).get()
        print(result)
        
        let userInfo = try await req.ciamClient.auth.getUser()
        print("info:\(userInfo)")

        let storageUser: User
        
        if let user = try? await User.query(on: req.db).filter(\.$siwaIdentifier == userInfo.sub).first() {
            storageUser = user
        } else {
            
            let userName = UUID().uuidString
            let password = try Bcrypt.hash(userName)
            // 创建用户
            let user = User(id: UUID(),
                            name: "\(Date())",
                            username: userName,
                            password: password,
                            siwaIdentifier: userInfo.sub)
            try? await user.save(on: req.db)
            storageUser = user
        }
        
        // 认证用户
        req.auth.login(storageUser)
        // 跳转首页
        return req.redirect(to: "/")
    }
    
    private func buildSIWAContext(on req: Request) throws -> SIWAContext {
        
        let state = [UInt8].random(count: 32).base64
        let scopes = "openId"
        
        let authUrl = req.ciamClient.generateAuthUrl()
        
        let siwa = SIWAContext.init(ciamAuthUrl: authUrl, scopes: scopes, state: state)
        
        return siwa
    }
    
    // CIAM logout http://127.0.0.1:8080/logout
    func ciamAuthLogoutHandler(_ req: Request) -> Response {
        guard req.auth.get(User.self) != nil else {
            return req.redirect(to: "/")
        }
        let url = req.ciamClient.ciamLogout()
        req.auth.logout(User.self)
        return req.redirect(to: url)
    }
}

struct IndexContext: Encodable {
  let title: String
  let loggedUser: User?
}

struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    let siwaContext: SIWAContext
    
    init(loginError: Bool = false, siwaContext: SIWAContext) {
        self.loginError = loginError
        self.siwaContext = siwaContext
    }
}

struct CiamAuthorizationResponse: Decodable {
    let code: String
}

struct SIWARedirectData: Content {
  let token: String
  let email: String?
  let firstName: String?
  let lastName: String?
}

struct SIWAContext: Encodable {
    let ciamAuthUrl: String
    let scopes: String
    let state: String
}
