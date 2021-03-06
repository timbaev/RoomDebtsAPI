//
//  EnvironmentExtensions.swift
//  App
//
//  Created by Timur Shafigullin on 02/02/2019.
//

import Vapor

extension Environment {
    
    // MARK: - Type Properties
    
    static var PUBLIC_URL: String {
        return Environment.get("PUBLIC_URL") ?? "http://localhost:\(Environment.PORT)"
    }
    
    static var PORT: Int {
        return Int(Environment.get("PORT") ?? "8080") ?? -1
    }
    
    static var STORAGE_PATH: [PathComponentsRepresentable] {
        return [Environment.get("STORAGE_PATH") ?? "Storage"]
    }

    static var FTS_LOGIN: String? {
        return Environment.get("FTS_LOGIN")
    }

    static var FTS_PASSWORD: String? {
        return Environment.get("FTS_PASSWORD")
    }
}
