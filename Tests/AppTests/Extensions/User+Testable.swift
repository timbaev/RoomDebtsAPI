//
//  User+Testable.swift
//  App
//
//  Created by Timur Shafigullin on 22/03/2019.
//

@testable import App
import Vapor
import FluentPostgreSQL

extension User {

    // MARK: - Type Methods

    static func create(firstName: String = "Test", lastName: String = "Testable", phoneNumber: String = "+71234567890", on conn: PostgreSQLConnection) throws -> User {
        let user = User(firstName: firstName, lastName: lastName, phoneNumber: phoneNumber)

        return try user.save(on: conn).wait()
    }
}
