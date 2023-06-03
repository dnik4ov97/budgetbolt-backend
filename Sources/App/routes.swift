import Vapor
import FluentKit

func routes(_ app: Application) throws {
    
    
    let clientName = "Niki Finance"
    let clientId = "63601ef71a807200137b674a"
    
//    let secret = "ff636de5c3dfcf4452cd512534eb6a"
//    let environment = "https://sandbox.plaid.com"
    let secret = "2dc5ba85eb536192413ea211f8d795"
//    let environment = "https://development.plaid.com"
//    let secret = "c2fe5a1ec1180ebd49d19806ac56dd"
//    let environment = "https://production.plaid.com"
    
    /*
     -------------------------------------------------------------------------------------------------------------------------------------------------------------------
        1) Create Link Token For Link to Accesss
     -------------------------------------------------------------------------------------------------------------------------------------------------------------------
     */
    struct ParamtersForLinkToken: Content {
        var client_id: String
        var secret: String
        var user: User
        var client_name: String
        var products: [String]
        var country_codes: [String]
        var language: String
        var redirect_uri: String
        
        struct User: Content {
            var client_user_id: String
        }
    }
    
    struct LinkToken: Content {
        var link_token: String
    }
    
    app.post("create_link_token") { req async in
        let userId = "1234"
        do {
            let response = try await req.client.post("https://development.plaid.com/link/token/create") {req in
                try req.content.encode(
                    ParamtersForLinkToken(client_id: clientId, secret: secret, user: ParamtersForLinkToken.User(client_user_id: userId), client_name: clientName,
                                    products: ["transactions"], country_codes: ["US"], language: "en", redirect_uri: "https://app.example.com/plaid")
                )
            }
            let decodeResponse = try response.content.decode(LinkToken.self)
            return decodeResponse
        } catch {
            print(error)
            return LinkToken(link_token: "")
        }
    }
    
   /*
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------
        1) Exchange Public Token From Link For An Access Token
        2) Store to MongoDB Database
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    */
    struct EmailWithAccess: Content {
        var email: String
        var publicKey: String
        var institutionId: String
        var institutionName: String
    }

    struct AccessToken: Content {
        var access_token: String
        var item_id: String
        var request_id: String
    }

    
    app.post("item_public_token_exchange") { req -> String in

        do {
            // decode JSON Email and Public Key
            let userAndPublicKey = try req.content.decode(EmailWithAccess.self)
            
            // Public Exchange for Access Token
            let publicExchangeResponse = try await req.client.post("https://development.plaid.com/item/public_token/exchange") { req in
                try req.content.encode(
                    ["client_id": clientId, "secret": secret, "public_token": userAndPublicKey.publicKey]
                )
            }
            // decode JSON Access Token
            let accessToken = try publicExchangeResponse.content.decode(AccessToken.self)
            
            
            // Get Current Access Tokens
            var oldAccessArray = try await Users.query(on: req.db)
                .filter(\.$email == userAndPublicKey.email)
                .field(\.$access)
                .first()!.access
            oldAccessArray.append(Access(access_token: accessToken.access_token, cursor: "", institution_id: userAndPublicKey.institutionId, name: userAndPublicKey.institutionName))
            
            try await Users.query(on: req.db)
                .set(\.$access, to: oldAccessArray)
                .filter(\.$email == userAndPublicKey.email)
                .update()
            return "done"
        } catch {
            print(error)
            return "error"
        }
    }

    
    /*
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------
            GET TRANSACTIONS WITH ACCESS TOKEN (FROM DATABASE)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    */
    app.post("get_account_transaction") { req async -> [Transactions.TransContent] in
//        var output = [Cat]()
        var transactionSync = Transactions(added: [Transactions.TransContent](), modified: [Transactions.TransContent](), removed: [Transactions.Removed](), next_cursor: "", has_more: false)
        do {
            // Get all the accessInfo for email
            let email = try req.content.decode(Email.self)
            let accessAccounts = try await findAccess(req, email)

//            try await Users.query(on: req.db)
//                .set(\.$transactions, to: transactionSync.added)
//                .filter(\.$email == email.address)
//                .update()
//            
//            for access in accessAccounts {
//                repeat {
//                    // Calling Transaction/Sync from Plaid
//                    let cursor = try await findAccess(req, email).first(where: {$0.access_token == access.access_token})?.cursor ?? ""
//                    print("DBcursor: \(cursor)")
//                    let requestFields = ["client_id": clientId, "secret": secret, "access_token" : access.access_token, "cursor": cursor]
//                    let response = try await req.client.post("https://development.plaid.com/transactions/sync") {req in
//                        try req.content.encode(requestFields)
//                    }
//                    transactionSync = try response.content.decode(Transactions.self)
//
//                    // Update Transaction in MongoDB --------------------------------------------------------------
//                    try await updateTransactions(trans: transactionSync, req: req, email: email)
//
//                    // Updating Finding and Updating the Cursor
//                    var accesses = try await Users.query(on: req.db)
//                        .filter(\.$email == email.address)
//                        .field(\.$access)
//                        .first()?.access ?? [Access]()
//                    accesses.removeAll(where: {$0.access_token == access.access_token})
//                    accesses.append(Access(access_token: access.access_token, cursor: transactionSync.next_cursor, institution_id: access.institution_id, name: access.name))
//
//                    try await Users.query(on: req.db)
//                        .set(\.$access, to: accesses)
//                        .filter(\.$email == email.address)
//                        .update()
//
//
//                } while transactionSync.has_more
//            }
            let dbTransaction = try await Users.query(on: req.db)
                .filter(\.$email == email.address)
                .field(\.$transactions)
                .first()?.transactions
            
//            let dbTransaction = try await Users.query(on: req.db)
//                .filter(\.$email == email.address)
//                .field(\.$transactions)
//                .first()?.transactions.uniqued(on: {trans in trans.category_id})
            
//            var categories = Categories(categories: [Categories.Category]())
//
//            do {
//                let emptyJSON : [String: String] = [:]
//                let response = try await req.client.post("https://development.plaid.com/categories/get") { req in
//                    try req.content.encode(emptyJSON)
//                }
////                print(response)
//                categories = try response.content.decode(Categories.self)
////                print(categories.categories)
////                return categories.categories
//            } catch {
//                print(error)
////                return [Categories.Category]()
//            }
            
//            for trans in dbTransaction! {
//                if categories.categories.contains(where: { $0.category_id == trans.category_id}) {
//                    output.append(Cat(cat_id: trans.category_id, cats: categories.categories.first(where: {$0.category_id == trans.category_id})!.hierarchy, transaction: trans.name))
//                }
//            }
        
            return dbTransaction!
//            return output
        } catch {
            print(error)
            return(transactionSync.added)
//            return output
        }
    }
    
    
    struct Cat: Content {
        var cat_id: String
        var cats: [String]
        var transaction: String
    }
    
    
    /*
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------
            GET ACCOUNTS BALANCE (FROM DATABASE)
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    */
    struct CapitalOneBalanceParam: Content {
        var client_id: String
        var secret: String
        var access_token: String
        var options: Option
        struct Option: Content {
            var min_last_updated_datetime: String
        }
    }
    
    app.post("get_account_balances") { req async -> [NewAccount] in
        let emptyAccounts = [NewAccount(account_id: "", balances: Accounts.Account.Balances(available: 0.0, current: 0.0, iso_currency_code: "", limit: 0.0), mask: "", name: "", subtype: "", type: "", institutionName: "")]
        var accounts = Accounts(accounts: [Accounts.Account]())
        var updatedAccounts = [NewAccount]()
        do {
            // Get all the accessTokens for email
            let email = try req.content.decode(Email.self)
            let accessAccounts = try await findAccess(req, email)

//            for access in accessAccounts {
//                print("access: \(access)")
//                do {
//                    let response = try await req.client.post("https://development.plaid.com/accounts/balance/get") { req in
//                        if access.institution_id == "ins_128026" {
//                            try req.content.encode(
//                                CapitalOneBalanceParam(client_id: clientId, secret: secret, access_token: access.access_token, options: CapitalOneBalanceParam.Option(min_last_updated_datetime: "2023-05-10T20:52:54Z"))
//                            )
//                        } else {
//                            try req.content.encode(
//                                ["client_id": clientId, "secret": secret, "access_token" : access.access_token]
//                            )
//                        }
//                    }
//                    accounts = try response.content.decode(Accounts.self)
//
//                    for account in accounts.accounts {
//                        var newBankName = getNewBankName(accountName: account.name, officialAccountName: account.official_name, institutionName: access.name)
//                        updatedAccounts.append(NewAccount(account_id: account.account_id, balances: account.balances, mask: account.mask, name: newBankName, subtype: account.subtype, type: account.type, institutionName: access.name))
//                    }
//
//                } catch {
//                    print("Error: \(error)")
//                }
//                // Update Accounts in MongoDB
//                try await updateAccounts(accounts: updatedAccounts, req: req, email: email)
//            }
            let dbAccounts = try await Users.query(on: req.db)
                .filter(\.$email == email.address)
                .field(\.$accounts)
                .first()?.accounts
            return dbAccounts!
        } catch {
            print(error)
            return emptyAccounts
        }
    }
}


func getNewBankName(accountName: String, officialAccountName: String?, institutionName: String ) -> String {
    if officialAccountName == nil {
        if accountName == "TOTAL CHECKING" && institutionName == "Chase" {
            return "Chase Total Checking"
        }
        return accountName
    } else {
        if officialAccountName == "Ultimate Rewards®" && institutionName == "Chase" {
            return "Chase Freedom Unlimited"
        }
        return officialAccountName!
    }
}

func updateAccounts (accounts: [NewAccount], req: Request, email: Email) async throws -> Void {
    // Grab Accounts from MongoDB
    var dbAccounts = try await Users.query(on: req.db)
        .filter(\.$email == email.address)
        .field(\.$accounts)
        .first()?.accounts
    
    
    // Update or Add new Accounts
    for account in accounts {
        print("updateAccounts() account: \(account)")
        if dbAccounts!.contains(where: {$0.account_id == account.account_id}) {
            dbAccounts!.removeAll(where: {$0.account_id == account.account_id})
            dbAccounts!.append(account)
        } else {
            dbAccounts!.append(account)
        }
    }
    
    // Update Accounts in MongoDB
    try await Users.query(on: req.db)
        .set(\.$accounts, to: dbAccounts!)
        .filter(\.$email == email.address)
        .update()
}

struct Transactions: Content{
    var added: [TransContent]
    var modified: [TransContent]
    var removed: [Removed]
    var next_cursor: String
    var has_more: Bool

    struct TransContent: Content{
        var account_id: String
        var amount: Double
        var iso_currency_code: String?
        var unofficial_currency_code: String?
        var category: [String]
        var category_id: String
        var date: String
        var location: Location
        var name: String
        var merchant_name: String?
        var original_description: String?
        var pending: Bool
        var pending_transaction_id: String?
        var transaction_id: String
        var authorized_date: String?
        var personal_finance_category: PersonalCategory?
    }
    
    struct PersonalCategory: Content {
        var primary: String
        var detailed: String
    }
    
    struct Location: Content {
        var address: String?
        var city: String?
        var region: String?
        var postal_code: String?
        var country: String?
        var lat: Double?
        var lon: Double?
        var store_number: String?
    }

    struct Removed: Content {
        var transaction_id: String
    }
}

struct Access: Content {
    var access_token: String
    var cursor: String
    var institution_id: String
    var name: String
}

struct Email: Content {
    var address: String
}

struct Accounts: Content {
    var accounts: [Account]
//    var item: Item
    
    struct Account: Content {
        var account_id: String
        var balances: Balances
        var mask: String?
        var name: String
        var official_name: String?
        var subtype: String?
        var type: String
        
        struct Balances: Content {
            var available: Double?
            var current: Double?
            var iso_currency_code: String?
            var limit: Double?
        }
    }
    
//    struct Item: Content {
//        var institution_id: String
//    }
}
    
struct NewAccount: Content {
    var account_id: String
    var balances: Accounts.Account.Balances
    var mask: String?
    var name: String
    var subtype: String?
    var type: String
    var institutionName: String
}




func findAccess (_ req: Request, _ email: Email) async throws -> [Access] {
    let accessQuery = try await Users.query(on: req.db)
        .filter(\.$email == email.address)
        .field(\.$access)
        .first()
    return accessQuery?.access ?? [Access]()
}


func updateTransactions (trans: Transactions, req: Request, email: Email) async throws-> Void {
    let added = trans.added
    let modified = trans.modified
    let removed = trans.removed
    
    var dbTransaction = try await Users.query(on: req.db)
        .filter(\.$email == email.address)
        .field(\.$transactions)
        .first()?.transactions
    
    // ?? Transactions Enrich!!!!!!!!! ---------------------------------------------------
    
    dbTransaction!.append(contentsOf: added)
    
    for transMod in modified {
        let index = dbTransaction!.firstIndex(where: {$0.transaction_id == transMod.transaction_id})!
        dbTransaction![index] = transMod
    }
    
    for transId in removed {
        dbTransaction!.removeAll(where: {$0.transaction_id == transId.transaction_id})
    }
    
    let sortedTransactions = dbTransaction!.sorted(by: {$0.date > $1.date})
    try await Users.query(on: req.db)
        .set(\.$transactions, to: sortedTransactions)
        .filter(\.$email == email.address)
        .update()
}

let category = [
    (category_id: "15002000",category: "Interest Charged"),
    (category_id: "18030000",category: "Service"),
    (category_id: "19047000",category: "Supermarkets and Groceries"),
    (category_id: "22009000",category: "Gas Stations"),
    (category_id: "16001000",category: "Credit Card"),
    (category_id: "15002000",category: "Interest Charged")
]

let transactionNames = [
    (oldName: "Peacock 7CFFD Premium", newName: "Peacock TV"),
    (oldName: "AMERICAN EXPRESS ACH PMT M0552 WEB ID: 2005032111", newName: "American Express Payment"),
    (oldName: "AMAZON MARKEPLACE NA", newName: "Amazon MarketPlace"),
]
