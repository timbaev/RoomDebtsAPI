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
    
    public enum Status: String, PostgreSQLEnum {
        
        // MARK: - Enumeration Cases
        
        case accepted
        case repayRequest
        case deleteRequest
        case invited
    }
    
    // MARK: -
    
    struct Form: Content {
        
        // MARK: - Instance Properties
        
        let id: Int?
        let creator: User.PublicForm
        let opponent: User.PublicForm
        let status: String
        let price: Double
        let debtorID: Int?
        let rejectStatus: String?

        var newDebtCount: Int?

        // MARK: - Initializers

        init(conversation: Conversation, creator: User, opponent: User) {
            self.id = conversation.id
            self.creator = User.PublicForm(user: creator)
            self.opponent = User.PublicForm(user: opponent)
            self.status = conversation.status.rawValue
            self.price = conversation.price
            self.debtorID = conversation.debtorID
            self.rejectStatus = conversation.rejectStatus?.rawValue
        }
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
    var rejectStatus: Status?
    var price: Double
    var debtorID: User.ID?

    var status: Status {
        didSet {
            self.rejectStatus = nil
        }
    }
    
    // MARK: - Initializers
    
    init(creatorID: User.ID, opponentID: User.ID, status: Status = .invited, price: Double = 0.0, debtorID: User.ID? = nil) {
        self.creatorID = creatorID
        self.opponentID = opponentID
        self.status = status
        self.price = price
        self.debtorID = debtorID
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

    var debts: Children<Conversation, Debt> {
        return self.children(\.conversationID)
    }

    var conversationVisits: Children<Conversation, ConversationVisit> {
        return self.children(\.conversationID)
    }
}

// MARK: - Future

extension Future where T: Conversation {

    // MARK: - Instance Methods

    func toForm(on request: Request) -> Future<Conversation.Form> {
        return self.flatMap(to: Conversation.Form.self, { conversation in
            return conversation
                .creator
                .get(on: request)
                .and(conversation.opponent.get(on: request))
                .map { (creator, opponent) in
                    return Conversation.Form(conversation: conversation, creator: creator, opponent: opponent)
            }
        })
    }
}
