//
//  ConversationVisit.swift
//  App
//
//  Created by Timur Shafigullin on 17/08/2019.
//

import Vapor
import FluentPostgreSQL

final class ConversationVisit: Object {

    // MARK: - Nested Types

    struct Form: Content {

        // MARK: - Instance Properties

        var id: Int?
        var userID: Int
        var conversationID: Int
        var visitDate: Date?

        // MARK: - Initializers

        init(conversationVisit: ConversationVisit) {
            self.id = conversationVisit.id
            self.userID = conversationVisit.userID
            self.conversationID = conversationVisit.conversationID
            self.visitDate = conversationVisit.visitDate
        }
    }

    // MARK: - Instance Properties

    var id: Int?
    var visitDate: Date

    var userID: User.ID
    var conversationID: User.ID

    // MARK: - Initializers

    init(id: Int? = nil, userID: User.ID, conversationID: Conversation.ID, visitDate: Date) {
        self.id = id
        self.userID = userID
        self.conversationID = conversationID
        self.visitDate = visitDate
    }
}

// MARK: - Relationships

extension ConversationVisit {

    // MARK: - Instance Properties

    var user: Parent<ConversationVisit, User> {
        return self.parent(\.userID)
    }

    var conversation: Parent<ConversationVisit, Conversation> {
        return self.parent(\.conversationID)
    }
}

// MARK: - Future

extension Future where T: ConversationVisit {

    // MARK: - Instance Methods

    func toForm() -> Future<ConversationVisit.Form> {
        return self.map(to: ConversationVisit.Form.self, { conversationVisit in
            return ConversationVisit.Form(conversationVisit: conversationVisit)
        })
    }
}
