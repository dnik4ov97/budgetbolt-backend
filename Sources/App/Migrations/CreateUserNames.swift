//
//  CreateUserNames.swift
//  
//
//  Created by David Nikiforov on 4/20/23.
//

import Foundation
import Fluent

struct CreateUserNames: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string)
            .field("password", .string)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("access_token", .array(of: .string))
            .field("transactions", .array(of: .custom(Transactions.TransContent.self)))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
