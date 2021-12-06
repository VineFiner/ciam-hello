//
//  File.swift
//  
//
//  Created by Finer  Vine on 2021/12/5.
//

import Foundation
import Fluent

struct CreateUser: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema("users")
      .id()
      .field("name", .string, .required)
      .field("username", .string, .required)
      .field("password", .string, .required)
      .field("siwaIdentifier", .string)
      .unique(on: "username")
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("users").delete()
  }
}
