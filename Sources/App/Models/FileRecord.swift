//
//  FileRecord.swift
//  App
//
//  Created by Timur Shafigullin on 02/02/2019.
//

import Vapor
import FluentPostgreSQL

final class FileRecord: Object {
    
    // MARK: - Nested Types
    
    struct Form: Content {
        
        // MARK: - Instance Properties
        
        var filename: String
        var fileKind: String?
        var publicURL: URL?
    }
    
    // MARK: - Type Properties
    
    public static var path: [PathComponentsRepresentable] {
        return ["files"]
    }
    
    // MARK: - Instance Properties
    
    var id: Int?
    var filename: String
    var fileKind: String?
    var localPath: String
    
    // MARK: - Initializers
    
    init(filename: String, fileKind: String? = nil, localPath: String) {
        self.filename = filename
        self.fileKind = fileKind
        self.localPath = localPath
    }
    
    // MARK: - Instance Methods
    
    func toForm() -> Form {
        if let id = self.id {
            let host = Environment.PUBLIC_URL
            
            let publicURL = URL(string: host)?.appendingPathComponent("\(FileRecord.path.convertToPathComponents().readable)/\(id)")
            
            return Form(filename: self.filename, fileKind: self.fileKind, publicURL: publicURL)
        }
        
        return Form(filename: self.filename, fileKind: self.fileKind, publicURL: nil)
    }
}

// MARK: - Future

extension Future where T: FileRecord {
    
    // MARK: - Instance Methods
    
    func toForm() -> Future<FileRecord.Form> {
        return self.map(to: FileRecord.Form.self, { fileRecord in
            return fileRecord.toForm()
        })
    }
}
