//
//  DefaultReceiptManager.swift
//  App
//
//  Created by Timur Shafigullin on 06/04/2019.
//

import Vapor

class DefaultReceiptManager: ReceiptManager {

    // MARK: - Instance Properties

    private var headers: HTTPHeaders = [
        "Device-Id": "12334567890",
        "Device-OS": "Adnroid 5.1",
        "Version": "2",
        "ClientVersion": "1.4.4.1",
        "Host": "proverkacheka.nalog.ru:9999",
        "Connection": "Keep-Alive",
        "Accept-Encoding": "gzip",
        "User-Agent": "okhttp/3.0.1"
    ]

    // MARK: - Instance Methods

    func checkReceiptExists(on request: Request, form: Check.QRCodeForm) throws -> Future<Bool> {
        let client = try request.make(Client.self)

        let url = "https://proverkacheka.nalog.ru:9999/v1/ofds/*/inns/*/fss/\(form.fn)/operations/\(form.n)/tickets/\(form.fd)?fiscalSign=\(form.fiscalSign)&sum=\(form.sum)&date=\(form.date)"

        return client.get(url, headers: self.headers).map { response in
            if response.http.status == .noContent {
                return true
            } else if response.http.status == .notAcceptable {
                return false
            } else if response.http.status == .badRequest {
                throw Abort(.badRequest, reason: "Missing required parameters".localized(on: request))
            } else {
                throw Abort(.badRequest, reason: "Unknown error from Federal Tax Service".localized(on: request))
            }
        }
    }

    func fetchReceiptContent(on request: Request, form: Check.QRCodeForm) throws -> Future<Receipt> {
        let client = try request.make(Client.self)

        let url = "https://proverkacheka.nalog.ru:9999/v1/inns/*/kkts/*/fss/\(form.fn)/tickets/\(form.fd)?fiscalSign=\(form.fiscalSign)&sendToEmail=no"

        guard let login = Environment.FTS_LOGIN, let password = Environment.FTS_PASSWORD else {
            throw Abort(.internalServerError, reason: "Missing login/password for Federal Tax Service".localized(on: request))
        }

        let loginPassword = "\(login):\(password)"
        let base64Login = Data(loginPassword.utf8).base64EncodedString(options: [])

        self.headers.add(name: .authorization, value: "Basic \(base64Login)")

        return client.get(url, headers: self.headers).flatMap { response in
            if response.http.status == .ok {
                let decoder = JSONDecoder()

                decoder.dateDecodingStrategy = .formatted(DateFormatter.receiptDateFormatter)

                return try response.content.decode(json: RawReceipt.self, using: decoder).map { rawReceipt in
                    return rawReceipt.document.receipt
                }
            } else if response.http.status == .forbidden {
                throw Abort(.forbidden, reason: "Login or password for Federal Tax Service incorrect".localized(on: request))
            } else if response.http.status == .notAcceptable {
                throw Abort(.badRequest, reason: "Check not found".localized(on: request))
            } else if response.http.status == .accepted {
                throw Abort(.badRequest, reason: "Check accepted".localized(on: request))
            } else {
                throw Abort(.badRequest, reason: "Unknown error from Federal Tax Service".localized(on: request))
            }
        }
    }
}
