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

    public enum Status: String, ReflectionDecodable, Codable {

        // MARK: - Enumeration Cases

        case accepted
        case newRequest
        case editRequest
        case closeRequest
        case deleteRequest

        // MARK: - Type Methods

        public static func reflectDecoded() throws -> (Debt.Status, Debt.Status) {
            return (.accepted, .deleteRequest)
        }
    }

    // MARK: -

    struct Form: Content {

        // MARK: - Instance Properties

        let id: Int?
        var price: Double
        var date: Date
        var description: String?
        var creator: User.PublicForm
        var debtorID: Int
        var status: String

        init(debt: Debt, creator: User.PublicForm) {
            self.id = debt.id
            self.price = debt.price
            self.date = debt.date
            self.description = debt.description
            self.creator = creator
            self.debtorID = debt.debtorID
            self.status = debt.status.rawValue
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

    // MARK: - Type Properties

    static var createdAtKey: TimestampKey? = \.createdAt

    // MARK: - Instance Properties

    var id: Int?
    var price: Double
    var date: Date
    var description: String?
    var status: Status
    var creatorID: User.ID
    var debtorID: User.ID
    var conversationID: Conversation.ID
    var createdAt: Date?

    // MARK: - Initializers

    init(price: Double, date: Date, description: String? = nil, creatorID: User.ID, debtorID: User.ID, conversationID: Conversation.ID, status: Debt.Status = .newRequest) {
        self.price = price
        self.date = date
        self.description = description
        self.creatorID = creatorID
        self.debtorID = debtorID
        self.conversationID = conversationID
        self.status = status
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
