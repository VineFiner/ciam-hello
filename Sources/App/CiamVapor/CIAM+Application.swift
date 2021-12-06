//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/11/22.
//

import Foundation
import Vapor
import OAuthSwiftCore
import CiamSwiftKit

/// 证书配置
extension Application {
    
    public var ciam: Ciam {
        .init(application: self, logger: self.logger)
    }
    
    private struct CiamCredentialsKey: StorageKey {
        typealias Value = ApplicationDefaultCredentials
    }
    
    public struct Ciam {
        public let application: Application
        public let logger: Logger
        
        /// 配置证书
        public var credentials: ApplicationDefaultCredentials {
            get {
                if let credentials = application.storage[CiamCredentialsKey.self] {
                    return credentials
                } else {
                    fatalError("Ciam credentials configuration has not been set. Use app.ciam.credentials = ...")
                }
            }
            nonmutating set {
                if application.storage[CiamCredentialsKey.self] == nil {
                    application.storage[CiamCredentialsKey.self] = newValue
                } else {
                    fatalError("Overriding credentials configuration after being set is not allowed.")
                }
            }
        }

    }
}
