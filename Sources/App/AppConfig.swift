//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/11/27.
//

import Foundation
import Vapor

struct AppConfig {
    
    var clientId: String
    var clientSecret: String
    var userDomain: String
    var redirectUri: String
    var logoutRedirectUrl: String
    var scopes: [String]
    
    /*
     touch .env
     echo "CIAM_CLIENTID=AAAA" >> .env
     echo "CIAM_CLIENTSECRET=AAAA" >> .env
     echo "CIAM_USERDOMAMIN=AAAA" >> .env
     echo "CIAM_REDIRECTURI=http://127.0.0.1:8080/callback" >> .env
     echo "CAIM_LOGOUTREDIRECTURL=http://127.0.0.1:8080/logout" >> .env
     */
    static var environment: AppConfig {
        guard let clientId = Environment.get("CIAM_CLIENTID"),
              let clientSecret = Environment.get("CIAM_CLIENTSECRET"),
              let userDomain = Environment.get("CIAM_USERDOMAMIN"),
              let redirectUri = Environment.get("CIAM_REDIRECTURI"),
              let logoutRedirectUrl = Environment.get("CAIM_LOGOUTREDIRECTURL") else {
                  fatalError("Please add app configuration to environment variables")
              }
        
        return .init(clientId: clientId,
                     clientSecret: clientSecret,
                     userDomain: userDomain,
                     redirectUri: redirectUri,
                     logoutRedirectUrl: logoutRedirectUrl,
                     scopes: ["openid"])
    }
}

extension Application {
    struct AppConfigKey: StorageKey {
        typealias Value = AppConfig
    }
    
    var config: AppConfig {
        get {
            storage[AppConfigKey.self] ?? .environment
        }
        set {
            storage[AppConfigKey.self] = newValue
        }
    }
}
