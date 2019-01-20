//
//  User.swift
//  App
//
//  Created by Timur Shafigullin on 19/01/2019.
//

import Vapor
import FluentPostgreSQL

final class User: PostgreSQLModel {
    
    // MARK: - Instance Properties

    var id: Int?
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var isConfirmed: Bool? = false
    
    // MARK: - Initializers
    
    init(id: Int, firstName: String, lastName: String, phoneNumber: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
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
