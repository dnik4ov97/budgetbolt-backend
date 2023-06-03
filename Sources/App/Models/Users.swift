//
//  Users.swift
//  
//
//  Created by David Nikiforov on 4/20/23.
//

import Foundation
import Fluent

final class Users: Model {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "access")
    var access: [Access]
    
    @Field(key: "transactions")
    var transactions: [Transactions.TransContent]
    
    @Field(key: "accounts")
    var accounts: [NewAccount]
    
   
    
    init() {}
    
    init(id: UUID? = nil, email: String, access: [Access], transactions: [Transactions.TransContent], accounts: [NewAccount]) {
        self.id = id
        self.email = email
        self.access = access
        self.transactions = transactions
        self.accounts = accounts
    }
}
