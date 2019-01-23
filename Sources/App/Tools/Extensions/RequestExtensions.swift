//
//  RequestExtensions.swift
//  App
//
//  Created by Timur Shafigullin on 23/01/2019.
//

import Vapor
import JWT

extension Request {
    
    // MARK: - Instance Properties
    
    var token: String {
        if let token = self.http.headers.firstValue(name: HTTPHeaderName.authorization) {
            return token
        } else {
            return ""
        }
    }
}
