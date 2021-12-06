//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/12/5.
//

import Foundation
import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$user)
    var todos: [Todo]
    
    @OptionalField(key: "siwaIdentifier")
    var siwaIdentifier: String?
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, password: String, siwaIdentifier: String? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.password = password
        self.siwaIdentifier = siwaIdentifier
    }
}

// MARK: 这里是 Session 验证器
extension User: ModelSessionAuthenticatable {}
