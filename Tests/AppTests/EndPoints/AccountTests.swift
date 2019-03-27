//
//  AccountTests.swift
//  AppTests
//
//  Created by Timur Shafigullin on 25/03/2019.
//

@testable import App
import Vapor
import FluentPostgreSQL
import XCTest

final class AccountTests: XCTestCase {

    // MARK: - Instance Properties

    let basePath = "v1/account"

    var app: Application!
    var conn: PostgreSQLConnection!

    // MARK: - Instance Methods

    func testCreateAccount() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        let expectedMessage = "Account created successfully"

        // act
        let response = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)
        let responseDto = try response.content.decode(ResponseDto.self).wait()

        // assert
        XCTAssertEqual(expectedMessage, responseDto.message)
    }

    func testCreateExistingAccount() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        let expectedMessage = "Account updated successfully"

        // act
        let _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)
        let responseDto = try self.app.getResponse(to: self.basePath, method: .POST, data: userForm, deocodeTo: ResponseDto.self)

        // assert
        XCTAssertEqual(expectedMessage, responseDto.message)
    }

    func testCreateExistingUserWithDeletedVerificationCode() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "Verification code not found"

        // act
        let _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        try VerificationCode.query(on: self.conn).delete().wait()

        let response = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedReason, abortContent.reason)
        XCTAssertTrue(abortContent.error)
    }

    func testCreateAlreadyConfirmedUser() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "User with phone number \(userForm.phoneNumber) already exists"

        // act
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        let user = try User.query(on: self.conn).first().unwrap(or: Abort(.badRequest)).wait()
        user.isConfirmed = true
        _ = try user.save(on: self.conn).wait()

        let response = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedReason, abortContent.reason)
        XCTAssertTrue(abortContent.error)
    }

    // MARK: -

    func testConfirmUser() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        guard let verificationCode = try VerificationCode.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: userForm.phoneNumber, code: verificationCode.code)

        // act
        let accessDto = try self.app.getResponse(to: self.basePath + "/confirm", method: .POST, data: confirmPhoneDto, deocodeTo: AccessDto.self)

        guard let user = try User.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        guard let refreshToken = try RefreshToken.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let expectedUserForm = User.Form(user: user)

        // assert
        XCTAssertNotNil(accessDto.accessToken)
        XCTAssertEqual(refreshToken.token, accessDto.refreshToken)
        XCTAssertNotNil(accessDto.expiredAt)
        XCTAssertNotNil(accessDto.userData)
        XCTAssertEqual(expectedUserForm, accessDto.userData)
    }

    func testConfirmNotExistingUser() throws {
        // arrange
        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: "+71234567890", code: "1234")
        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "User with phone number \(confirmPhoneDto.phoneNumber) not found"

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/confirm", method: .POST, body: confirmPhoneDto)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertTrue(abortContent.error)
        XCTAssertEqual(expectedReason, abortContent.reason)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
    }

    func testConfirmWithoutVerificationCode() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        try VerificationCode.query(on: self.conn).delete().wait()

        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: "+71234567890", code: "1234")

        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "Verification code not found"

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/confirm", method: .POST, body: confirmPhoneDto)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertTrue(abortContent.error)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedReason, abortContent.reason)
    }

    func testConfirmExpiredVerificationCode() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        guard let verificationCode = try VerificationCode.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        verificationCode.expiredAt = Date()

        _ = try verificationCode.save(on: self.conn).wait()

        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: userForm.phoneNumber, code: verificationCode.code)

        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "Verification code expired"

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/confirm", method: .POST, body: confirmPhoneDto)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertTrue(abortContent.error)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedReason, abortContent.reason)
    }

    func testConfirmWithInvalidVerificationCode() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: userForm.phoneNumber, code: "----")

        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "Invalid verification code"

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/confirm", method: .POST, body: confirmPhoneDto)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertTrue(abortContent.error)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedReason, abortContent.reason)
    }

    // MARK: -

    func testRefreshToken() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        guard let verificationCode = try VerificationCode.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: userForm.phoneNumber, code: verificationCode.code)
        let _ = try self.app.sendRequest(to: self.basePath + "/confirm", method: .POST, body: confirmPhoneDto)

        guard let refreshToken = try RefreshToken.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let accessDto = AccessDto(accessToken: nil, refreshToken: refreshToken.token, expiredAt: nil, userData: nil)

        // act
        let responseAccessDto = try self.app.getResponse(to: self.basePath + "/token", method: .POST, data: accessDto, deocodeTo: AccessDto.self)

        guard let updatedRefreshToken = try RefreshToken.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        // assert
        XCTAssertNotNil(responseAccessDto.accessToken)
        XCTAssertEqual(updatedRefreshToken.token, responseAccessDto.refreshToken)
        XCTAssertNotNil(responseAccessDto.expiredAt)
        XCTAssertTrue(responseAccessDto.expiredAt! > Date())
        XCTAssertNil(responseAccessDto.userData)
    }

    func testRefreshTokenWithInvalidToken() throws {
        // arrange
        let accessDto = AccessDto(accessToken: nil, refreshToken: "none", expiredAt: nil, userData: nil)

        let expectedHttpStatus = HTTPStatus.unauthorized

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/token", method: .POST, body: accessDto)

        // assert
        XCTAssertEqual(expectedHttpStatus, response.http.status)
    }

    func testRefreshTokenWithExpiredDate() throws {
        // arrange
        let userForm = User.Form(user: User(firstName: "Test", lastName: "Testable", phoneNumber: "+71234567890"))
        _ = try self.app.sendRequest(to: self.basePath, method: .POST, body: userForm)

        guard let verificationCode = try VerificationCode.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let confirmPhoneDto = ConfirmPhoneDto(phoneNumber: userForm.phoneNumber, code: verificationCode.code)
        let _ = try self.app.sendRequest(to: self.basePath + "/confirm", method: .POST, body: confirmPhoneDto)

        guard let refreshToken = try RefreshToken.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        refreshToken.expiredAt = Date()
        _ = try refreshToken.save(on: self.conn).wait()
        let accessDto = AccessDto(accessToken: nil, refreshToken: refreshToken.token, expiredAt: nil, userData: nil)

        let expectedHttpStatus = HTTPStatus.unauthorized

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/token", method: .POST, body: accessDto)

        // assert
        XCTAssertEqual(expectedHttpStatus, response.http.status)
    }

    // MARK: -

    func testSignIn() throws {
        // arrange
        let user = try User.create(on: self.conn)

        let phoneNumberDto = PhoneNumberDto(phoneNumber: user.phoneNumber)

        let expectedMessage = "Verification code sent"

        // act
        let responseDto = try self.app.getResponse(to: self.basePath + "/login", method: .POST, data: phoneNumberDto, deocodeTo: ResponseDto.self)

        // assert
        XCTAssertEqual(expectedMessage, responseDto.message)
    }

    func testSignInWithNonexistentUser() throws {
        // arrange
        let phoneNumberDto = PhoneNumberDto(phoneNumber: "+71234567890")

        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "User with phone number \(phoneNumberDto.phoneNumber) not found"

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/login", method: .POST, body: phoneNumberDto)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertTrue(abortContent.error)
        XCTAssertEqual(expectedReason, abortContent.reason)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
    }

    func testSignInWithExistingVerificationCode() throws {
        // arrange
        let user = try User.create(on: self.conn)
        let verificationCode = try VerificationCode(userID: try user.requireID()).save(on: self.conn).wait()
        let phoneNumberDto = PhoneNumberDto(phoneNumber: user.phoneNumber)
        let expectedMessage = "Verification code sent"

        // act
        let responseDto = try self.app.getResponse(to: self.basePath + "/login", method: .POST, data: phoneNumberDto, deocodeTo: ResponseDto.self)

        guard let updatedVerificationCode = try VerificationCode.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        // assert
        XCTAssertEqual(expectedMessage, responseDto.message)
        XCTAssertNotEqual(verificationCode.code, updatedVerificationCode.code)
        XCTAssertTrue(updatedVerificationCode.expiredAt > verificationCode.expiredAt)
    }

    // MARK: -

    func testUpdateAccount() throws {
        // arrange
        let user = try User.create(on: self.conn)

        let expectedFirstName = "Update"
        let expectedLastName = "Updatable"

        let userForm = User.Form(user: User(firstName: expectedFirstName, lastName: expectedLastName, phoneNumber: user.phoneNumber))

        // act
        let responseUserForm = try self.app.getResponse(to: self.basePath, method: .PUT, data: userForm, deocodeTo: User.Form.self, authenticatedUser: user)

        // assert
        XCTAssertEqual(expectedFirstName, responseUserForm.firstName)
        XCTAssertEqual(expectedLastName, responseUserForm.lastName)
    }

    func testUpdateAccountWithPhoneNumber() throws {
        // arrange
        let user = try User.create(on: self.conn)

        let expectedFirstName = "Update"
        let expectedLastName = "Updatable"
        let expectedPhoneNumber = "+71234560000"
        let expectedHttpStatus = HTTPStatus.accepted

        let userForm = User.Form(user: User(firstName: expectedFirstName, lastName: expectedLastName, phoneNumber: expectedPhoneNumber))

        // act
        let response = try self.app.sendRequest(to: self.basePath, method: .PUT, body: userForm, authenticatedUser: user)
        let responseUserForm = try response.content.decode(User.Form.self).wait()

        let verificationCode = try VerificationCode.query(on: self.conn).first().wait()

        // assert
        XCTAssertNotNil(verificationCode)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedFirstName, responseUserForm.firstName)
        XCTAssertEqual(expectedLastName, responseUserForm.lastName)
        XCTAssertEqual(expectedPhoneNumber, responseUserForm.phoneNumber)
    }

    func testUpdateAccountWithAlreadyExistsPhoneNumber() throws {
        // arrange
        let user = try User.create(phoneNumber: "+71234560000", on: self.conn)
        let authenticatedUser = try User.create(on: self.conn)

        let userForm = User.Form(user: User(firstName: authenticatedUser.firstName, lastName: authenticatedUser.lastName, phoneNumber: user.phoneNumber))

        let expectedHttpStatus = HTTPStatus.badRequest
        let expectedReason = "User with phone number already exists"

        // act
        let response = try self.app.sendRequest(to: self.basePath, method: .PUT, body: userForm, authenticatedUser: authenticatedUser)
        let abortContent = try response.content.decode(AbortContent.self).wait()

        // assert
        XCTAssertTrue(abortContent.error)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertEqual(expectedReason, abortContent.reason)
    }

    func testUpdateAccountPhoneNumberWithExistingVerificationCode() throws {
        // arrange
        let user = try User.create(on: self.conn)
        let verificationCode = try VerificationCode(userID: try user.requireID()).save(on: self.conn).wait()

        let expectedPhoneNumber = "+712334560000"
        let expectedHttpStatus = HTTPStatus.accepted

        let userForm = User.Form(user: User(firstName: user.firstName, lastName: user.lastName, phoneNumber: expectedPhoneNumber))

        // act
        let response = try self.app.sendRequest(to: self.basePath, method: .PUT, body: userForm, authenticatedUser: user)
        let responseUserForm = try response.content.decode(User.Form.self).wait()

        guard let updatedVerificationCode = try VerificationCode.query(on: self.conn).first().wait() else {
            return XCTFail("Verification code not found")
        }

        // assert
        XCTAssertEqual(expectedPhoneNumber, responseUserForm.phoneNumber)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
        XCTAssertTrue(verificationCode.expiredAt < updatedVerificationCode.expiredAt)
        XCTAssertNotEqual(verificationCode.code, updatedVerificationCode.code)
    }

    // MARK: -

    func testLogout() throws {
        // arrange
        let user = try User.create(on: self.conn)
        let _ = try RefreshToken(token: "Token", userID: try user.requireID()).save(on: self.conn).wait()

        let expectedHttpStatus = HTTPStatus.noContent

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/logout", method: .POST, body: EmptyBody(), authenticatedUser: user)
        let refreshTokenCount = try RefreshToken.query(on: self.conn).count().wait()

        // assert
        XCTAssertTrue(refreshTokenCount == 0)
        XCTAssertEqual(expectedHttpStatus, response.http.status)
    }

    // MARK: -

    func testUploadImage() throws {
        // arrange
        let user = try User.create(on: self.conn)
        let directory = DirectoryConfig.detect()
        let resourcesDir = "Tests/AppTests/Resources"

        let data = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(resourcesDir, isDirectory: true)
            .appendingPathComponent("test.png", isDirectory: false))

        let expectedFilename = "picture.test"
        let expectedFileKind = "test"
        let expectedImageURL = "http://localhost:8080/files/"

        let file = File(data: data, filename: "picture.test")

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/avatar", file: file, authenticatedUser: user)
        let userForm = try response.content.decode(User.Form.self).wait()

        guard let fileRecord = try FileRecord.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        guard let updatedUser = try User.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let url = URL(fileURLWithPath: directory.workDir).appendingPathComponent(fileRecord.localPath)

        // assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(expectedFilename, fileRecord.filename)
        XCTAssertEqual(expectedFileKind, fileRecord.fileKind)
        XCTAssertEqual(expectedImageURL + "\(try fileRecord.requireID())", userForm.imageURL?.absoluteString)
        XCTAssertEqual(updatedUser.imageID, fileRecord.id)
    }

    func testUploadImageWithExistingImage() throws {
        // arrange
        var user = try User.create(on: self.conn)
        let fileRecord = try FileRecord(filename: "delete_test.png", fileKind: "png", localPath: "Tests/AppTests/Resources/delete_test.png").save(on: self.conn).wait()

        user.imageID = try fileRecord.requireID()
        user = try user.save(on: self.conn).wait()

        let directory = DirectoryConfig.detect()
        let resourcesDir = "Tests/AppTests/Resources"

        let deletedFileURL = URL(fileURLWithPath: directory.workDir).appendingPathComponent(fileRecord.localPath)

        let data = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(resourcesDir, isDirectory: true)
            .appendingPathComponent("test.png", isDirectory: false))

        let expectedFilename = "picture.test"
        let expectedFileKind = "test"
        let expectedImageURL = "http://localhost:8080/files/"

        let file = File(data: data, filename: "picture.test")

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/avatar", file: file, authenticatedUser: user)
        let userForm = try response.content.decode(User.Form.self).wait()

        guard let newFileRecord = try FileRecord.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        guard let updatedUser = try User.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let newFileURL = URL(fileURLWithPath: directory.workDir).appendingPathComponent(newFileRecord.localPath)

        // assert
        XCTAssertFalse(FileManager.default.fileExists(atPath: deletedFileURL.path))
        XCTAssertNotEqual(fileRecord.id, newFileRecord.id)
        XCTAssertNotEqual(user.imageID, updatedUser.imageID)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFileURL.path))
        XCTAssertEqual(expectedFilename, newFileRecord.filename)
        XCTAssertEqual(expectedFileKind, newFileRecord.fileKind)
        XCTAssertEqual(expectedImageURL + "\(try newFileRecord.requireID())", userForm.imageURL?.absoluteString)
        XCTAssertEqual(updatedUser.imageID, newFileRecord.id)
    }

    func testUploadImageWithNonexistentPath() throws {
        // arrange
        var user = try User.create(on: self.conn)
        let fileRecord = try FileRecord(filename: "test.png", fileKind: "png", localPath: "Tests/Icorrect/Path").save(on: self.conn).wait()

        user.imageID = try fileRecord.requireID()
        user = try user.save(on: self.conn).wait()

        let directory = DirectoryConfig.detect()
        let resourcesDir = "Tests/AppTests/Resources"

        let data = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(resourcesDir, isDirectory: true)
            .appendingPathComponent("test.png", isDirectory: false))

        let file = File(data: data, filename: "picture.test")

        let expectedHttpStatus = HTTPStatus.notFound

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/avatar", file: file, authenticatedUser: user)

        // assert
        XCTAssertEqual(expectedHttpStatus, response.http.status)
    }

    func testUploadImageWithoutExtension() throws {
        // arrange
        let user = try User.create(on: self.conn)
        let directory = DirectoryConfig.detect()
        let resourcesDir = "Tests/AppTests/Resources"

        let data = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(resourcesDir, isDirectory: true)
            .appendingPathComponent("test.png", isDirectory: false))

        let expectedFilename = "picture"
        let expectedImageURL = "http://localhost:8080/files/"

        let file = File(data: data, filename: "picture")

        // act
        let response = try self.app.sendRequest(to: self.basePath + "/avatar", file: file, authenticatedUser: user)
        let userForm = try response.content.decode(User.Form.self).wait()

        guard let fileRecord = try FileRecord.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        guard let updatedUser = try User.query(on: self.conn).first().wait() else {
            return XCTFail()
        }

        let url = URL(fileURLWithPath: directory.workDir).appendingPathComponent(fileRecord.localPath)

        // assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(expectedFilename, fileRecord.filename)
        XCTAssertNil(fileRecord.fileKind)
        XCTAssertEqual(expectedImageURL + "\(try fileRecord.requireID())", userForm.imageURL?.absoluteString)
        XCTAssertEqual(updatedUser.imageID, fileRecord.id)
    }

    // MARK: - XCTestCase

    override func setUp() {
        super.setUp()

        try! Application.reset()

        self.app = try! Application.testable()
        self.conn = try! app.newConnection(to: .psql).wait()

        let directory = DirectoryConfig.detect()
        let resourcesDir = "Tests/AppTests/Resources"

        let sourceURL = URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(resourcesDir, isDirectory: true)
            .appendingPathComponent("test.png", isDirectory: false)

        let destinationURL = URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(resourcesDir, isDirectory: true)
            .appendingPathComponent("delete_test.png", isDirectory: false)

        try! FileManager.default.copyItemIfNeeded(at: sourceURL, to: destinationURL)
    }

    override func tearDown() {
        conn.close()
        try? app.syncShutdownGracefully()

        let directory = DirectoryConfig.detect()
        let testRecources = Environment.STORAGE_PATH.convertToPathComponents().readable + "/test"
        let otherResources = Environment.STORAGE_PATH.convertToPathComponents().readable + "/other"
        let path = URL(fileURLWithPath: directory.workDir).appendingPathComponent(testRecources, isDirectory: true)
        let otherPath = URL(fileURLWithPath: directory.workDir).appendingPathComponent(otherResources, isDirectory: true)
        try? FileManager.default.removeItem(at: path)
        try? FileManager.default.removeItem(at: otherPath)

        super.tearDown()
    }
}
