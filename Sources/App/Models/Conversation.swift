//
//  Conversation.swift
//  App
//
//  Created by Timur Shafigullin on 03/02/2019.
//

import Vapor
import FluentPostgreSQL

final class Conversation: Object {
    
    // MARK: - Nested Types
    
    public enum Status: String, ReflectionDecodable, Codable {
        
        // MARK: - Enumeration Cases
        
        case accepted
        case invited
        
        // MARK: - Type Methods
        
        public static func reflectDecoded() throws -> (Conversation.Status, Conversation.Status) {
            return (.accepted, .invited)
        }
    }
    
    // MARK: -
    
    struct Form: Content {
        
        // MARK: - Instance Properties
        
        let id: Int?
        let creatorID: Int
        let opponentID: Int
        let status: String
        let price: Double
        let debtorID: Int?
    }
    
    // MARK: -
    
    struct CreateForm: Content {
        
        // MARK: - Instance Properties
        
        let opponentID: Int
    }
    
    // MARK: - Instance Properties
    
    var id: Int?
    var creatorID: User.ID
    var opponentID: User.ID
    var status: Status
    var price: Double
    var debtorID: User.ID?
    
    // MARK: - Initializers
    
    init(creatorID: User.ID, opponentID: User.ID, status: Status = .invited, price: Double = 0.0, debtorID: User.ID? = nil) {
        self.creatorID = creatorID
        self.opponentID = opponentID
        self.status = status
        self.price = price
        self.debtorID = debtorID
    }
    
    // MARK: - Instance Methods
    
    func toForm() -> Form {
        return Form(id: self.id, creatorID: self.creatorID, opponentID: self.opponentID, status: self.status.rawValue, price: self.price, debtorID: self.debtorID)
    }
}

// MARK: -

extension Conversation {
    
    // MARK: - Instance Properties
    
    var creator: Parent<Conversation, User> {
        return self.parent(\.creatorID)
    }
    
    var opponent: Parent<Conversation, User> {
        return self.parent(\.opponentID)
    }
    
    var debtor: Parent<Conversation, User>? {
        return self.parent(\.debtorID)
    }
}

// MARK: - Migration

extension Conversation {
    
    // MARK: - Type Methods
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(Conversation.self, on: connection) { builder in
            builder.field(for: \.status, type: .text)
        }
    }
}

// MARK: - Future

extension Future where T: Conversation {
    
    // MARK: - Instance Methods
    
    func toForm() -> Future<Conversation.Form> {
        return self.map(to: Conversation.Form.self, { conversation in
            return conversation.toForm()
        })
    }
}
