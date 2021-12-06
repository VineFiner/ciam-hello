//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/11/28.
//

import Foundation
import Vapor
import CiamSwiftKit

/// 认证 API
extension Application.Ciam {

    private struct CiamAuthKey: StorageKey {
        typealias Value = CiamAuthenticatorAPI
    }

    public var auth: CiamAuthenticatorAPI {
        get {
            if let existing = self.application.storage[CiamAuthKey.self] {
                return existing
            } else {
                return .init(application: self.application, eventLoop: self.application.eventLoopGroup.next(), logger: self.logger)
            }
        }

        nonmutating set {
            self.application.storage[CiamAuthKey.self] = newValue
        }
    }

    private struct CiamConfigurationKey: StorageKey {
        typealias Value = CiamConfiguration
    }
    /// Custom `HTTPClient` that ignores unclean SSL shutdown.
    private struct CiamHTTPClientKey: StorageKey, LockKey {
        typealias Value = HTTPClient
    }

    // MARK: API
    public struct CiamAuthenticatorAPI {
        public let application: Application
        public let eventLoop: EventLoop
        public let logger: Logger

        public var client: CiamClient {
            let new =  CiamClient.init(credentials: self.application.ciam.credentials,
                                       config: self.configuration,
                                       httpClient: self.http,
                                       eventLoop: self.eventLoop,
                                       logger: self.logger)
            return new
        }

        /// The configuration for using `Ciam` APIs.
        public var configuration: CiamConfiguration {
            get {
                if let configuration = application.storage[CiamConfigurationKey.self] {
                   return configuration
                } else {
                    fatalError("ciam configuration has not been set. Use app.ciam.auth.configuration = ...")
                }
            }
            set {
                if application.storage[CiamConfigurationKey.self] == nil {
                    application.storage[CiamConfigurationKey.self] = newValue
                } else {
                    fatalError("Attempting to override credentials configuration after being set is not allowed.")
                }
            }
        }

        public var http: HTTPClient {
            if let existing = application.storage[CiamHTTPClientKey.self] {
                return existing
            } else {
                let lock = application.locks.lock(for: CiamHTTPClientKey.self)
                lock.lock()
                defer { lock.unlock() }
                if let existing = application.storage[CiamHTTPClientKey.self] {
                    return existing
                }
                let new = HTTPClient(
                    eventLoopGroupProvider: .shared(application.eventLoopGroup),
                    configuration: HTTPClient.Configuration(ignoreUncleanSSLShutdown: true)
                )
                application.storage.set(CiamHTTPClientKey.self, to: new) {
                    try $0.syncShutdown()
                }
                return new
            }
        }
    }
}

extension Request {

    private struct CiamClientKey: StorageKey {
        typealias Value = CiamClient
    }

    public var ciamClient: CiamClient {
        if let existing = application.storage[CiamClientKey.self] {
            return existing.hopped(to: self.eventLoop)
        } else {
            let client = Application.Ciam.CiamAuthenticatorAPI.init(application: self.application, eventLoop: self.eventLoop, logger: self.logger).client
            application.storage[CiamClientKey.self] = client
            return client
        }
    }
}
