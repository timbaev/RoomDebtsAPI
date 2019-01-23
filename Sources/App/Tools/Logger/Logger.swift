//
//  Logger.swift
//  App
//
//  Created by Timur Shafigullin on 23/01/2019.
//

import Vapor

class Logger: Middleware {
    
    // MARK: - Instance Properties
    
    fileprivate var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.y HH:mm:ss"
        return dateFormatter
    }
    
    // MARK: - Instance Methods
    
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let requestTime = Date()
        let remoteAddress = request.http.remotePeer.hostname ?? "-"
        let method = request.http.method
        let url = request.http.url
        
        return try next.respond(to: request).then { response in
            let responseTime = Date().timeIntervalSince(requestTime)
            let status = response.http.status.code
            let httpVersion = "HTTP/\(response.http.version.major).\(response.http.version.minor)"
            
            var remoteUserID = "-"
            if let userID = try? TokenHelpers.getUserID(fromPayloadOf: request.token) {
                remoteUserID = "\(userID)"
            }
            
            var responseContentLength = "-"
            if let bodyCount = response.http.body.count {
                responseContentLength = "\(bodyCount)"
            }
            
            let userAgent = request.http.headers.firstValue(name: .userAgent) ?? "-"
            
            var content: String = {
                return """
                -----------------------------------------
                Request Time: \(self.dateFormatter.string(from: requestTime))
                Remote Address: \(remoteAddress)
                Remote User ID: \(remoteUserID)
                Response Time: \(responseTime) ms
                HTTP Method: \(method)
                URL: \(url)
                HTTP Version: \(httpVersion)
                Status Code: \(status)
                Response Content Length: \(responseContentLength)
                User Agent: \(userAgent)
                -----------------------------------------
                """
            }()
            
            content += "\n"
            
            print(content)
            
            return request.future(response)
        }
    }
}
