//
//  User.swift
//  App
//
//  Created by Timur Shafigullin on 19/01/2019.
//

import Vapor
import FluentPostgreSQL

final class User: PostgreSQLModel {
    
    // MARK: - Nested Types
    
    struct Form: Content {
        
        // MARK: - Instance Properties
        
        let id: Int?
        let firstName: String
        let lastName: String
        let phoneNumber: String
        let imageURL: URL?
        
        // MARK: - Initializers
        
        init(user: User, image: FileRecord.Form? = nil) {
            self.id = user.id
            self.firstName = user.firstName
            self.lastName = user.lastName
            self.phoneNumber = user.phoneNumber
            self.imageURL = image?.publicURL
        }
    }
    
    // MARK: - Instance Properties

    var id: Int?
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var imageID: FileRecord.ID?
    
    var isConfirmed = false
    
    // MARK: - Initializers
    
    init(id: Int? = nil, firstName: String, lastName: String, phoneNumber: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
    }
}

// MARK: -

extension User {
    
    // MARK: - Instance Properties
    
    var refreshTokens: Children<User, RefreshToken> {
        return self.children(\.userID)
    }
    
    var image: Parent<User, FileRecord>? {
        return self.parent(\.imageID)
    }
    
    var asCreatorConversations: Children<User, Conversation> {
        return self.children(\.creatorID)
    }
    
    var asOpponentConversations: Children<User, Conversation> {
        return self.children(\.opponentID)
    }
    
    var asDebtorConversations: Children<User, Conversation> {
        return self.children(\.debtorID)
    }
}

// MARK: - Content
extension User: Content { }

// MARK: - Migration
extension User: PostgreSQLMigration {
    
    // MARK: - Instance Methods
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.update(User.self, on: connection) { builder in
            builder.deleteField(for: \.isConfirmed)
            builder.field(for: \.isConfirmed, type: .bool, .default(.literal(.boolean(.false))))
            builder.unique(on: \.phoneNumber)
        }
    }
}

// MARK: - Parameter
extension User: Parameter { }

// MARK: - Future

extension Future where T: User {
    
    // MARK: - Instance Methods
    
    func toForm(on request: Request) -> Future<User.Form> {
        return self.flatMap(to: User.Form.self, { user in
            if let image = user.image {
                return image.get(on: request).map(to: User.Form.self, { fileRecord in
                    return User.Form(user: user, image: fileRecord.toForm())
                })
            } else {
                return self.map(to: User.Form.self, { user in
                    return User.Form(user: user)
                })
            }
        })
    }
}
