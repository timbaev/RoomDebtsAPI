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
        
        init(user: User) {
            self.id = user.id
            self.firstName = user.firstName
            self.lastName = user.lastName
            self.phoneNumber = user.phoneNumber

            if let imageID = user.imageID {
                self.imageURL = FileRecord.publicURL(withID: imageID)
            } else {
                self.imageURL = nil
            }
        }
    }
    
    // MARK: -
    
    struct PublicForm: Content {

        // MARK: - Nested Types

        private enum CodingKeys: String, CodingKey {

            // MARK: - Enumeration Cases

            case id
            case firstName
            case lastName
            case imageURL
            case imageID
        }
        
        // MARK: - Instance Properties
        
        let id: Int?
        let firstName: String
        let lastName: String
        let imageURL: URL?

        // MARK: - Initializers
        
        init(user: User) {
            self.id = user.id
            self.firstName = user.firstName
            self.lastName = user.lastName
            
            if let imageID = user.imageID {
                self.imageURL = FileRecord.publicURL(withID: imageID)
            } else {
                self.imageURL = nil
            }
        }

        public init(from decoder: Decoder) throws {
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)

            self.id = try keyedContainer.decodeIfPresent(Int.self, forKey: .id)
            self.firstName = try keyedContainer.decode(String.self, forKey: .firstName)
            self.lastName = try keyedContainer.decode(String.self, forKey: .lastName)

            if let imageID = try keyedContainer.decodeIfPresent(Int.self, forKey: .imageID) {
                self.imageURL = FileRecord.publicURL(withID: imageID)
            } else {
                self.imageURL = nil
            }
        }

        // MARK: - Encodable

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encodeIfPresent(self.id, forKey: .id)
            try container.encode(self.firstName, forKey: .firstName)
            try container.encode(self.lastName, forKey: .lastName)
            try container.encodeIfPresent(self.imageURL, forKey: .imageURL)
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

    var asCreatorDebts: Children<User, Debt> {
        return self.children(\.creatorID)
    }

    var asDebtorDebts: Children<User, Debt> {
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
    
    func toForm() -> Future<User.Form> {
        return self.flatMap(to: User.Form.self, { user in
            return self.map(to: User.Form.self, { user in
                return User.Form(user: user)
            })
        })
    }
}
