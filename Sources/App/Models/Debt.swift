//
//  Debt.swift
//  App
//
//  Created by Timur Shafigullin on 04/03/2019.
//

import Vapor
import FluentPostgreSQL

final class Debt: Object {

    // MARK: - Nested Types

    struct Form: Content {

        // MARK: - Instance Properties

        let id: Int?
        var price: Double
        var date: Date
        var description: String?
        var creator: User.PublicForm
        var debtorID: Int

        init(debt: Debt, creator: User.PublicForm) {
            self.id = debt.id
            self.price = debt.price
            self.date = debt.date
            self.description = debt.description
            self.creator = creator
            self.debtorID = debt.debtorID
        }
    }

    // MARK: -

    struct CreateForm: Content {

        // MARK: - Instance Properties

        var price: Double
        var date: Date
        var description: String?
        var debtorID: Int
        var conversationID: Int
    }

    // MARK: - Instance Properties

    var id: Int?
    var price: Double
    var date: Date
    var description: String?
    var creatorID: User.ID
    var debtorID: User.ID
    var conversationID: Conversation.ID

    // MARK: - Initializers

    init(price: Double = 0.0, date: Date, description: String? = nil, creatorID: User.ID, debtorID: User.ID, conversationID: Conversation.ID) {
        self.price = price
        self.date = date
        self.description = description
        self.creatorID = creatorID
        self.debtorID = debtorID
        self.conversationID = conversationID
    }

    convenience init(form: Debt.CreateForm, creatorID: User.ID) {
        self.init(price: form.price, date: form.date, description: form.description, creatorID: creatorID, debtorID: form.debtorID, conversationID: form.conversationID)
    }
}

// MARK: -

extension Debt {

    // MARK: - Instance Properties

    var creator: Parent<Debt, User> {
        return self.parent(\.creatorID)
    }

    var debtor: Parent<Debt, User> {
        return self.parent(\.debtorID)
    }

    var conversation: Parent<Debt, Conversation> {
        return self.parent(\.conversationID)
    }
}
