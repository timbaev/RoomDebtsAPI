//
//  FileController.swift
//  App
//
//  Created by Timur Shafigullin on 02/02/2019.
//

import Vapor

final class FileController {
    
    // MARK: - Instance Properties
    
    var fileService: FileService
    
    // MARK: - Initialierz
    
    init(fileService: FileService) {
        self.fileService = fileService
    }
    
    // MARK: - Instance Methods
    
    func download(_ request: Request) throws -> Future<Response> {
        return try request.parameters.next(FileRecord.self).flatMap(to: Response.self, { fileRecord in
            return try self.fileService.download(request: request, fileRecord: fileRecord)
        }).catchFlatMap { error in
            throw Abort(.notFound)
        }
    }
}

// MARK: - RouteCollection

extension FileController: RouteCollection {
    
    // MARK: - Instance Methods
    
    func boot(router: Router) throws {
        let group = router.grouped(FileRecord.path).grouped(ConsoleLogger())
        
        group.get(FileRecord.parameter, use: self.download)
    }
}
