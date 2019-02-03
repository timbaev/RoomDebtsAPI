//
//  FileService.swift
//  App
//
//  Created by Timur Shafigullin on 02/02/2019.
//

import Vapor

protocol FileService {
    
    // MARK: - Instance Methods
    
    func download(request: Request, fileRecord: FileRecord) throws -> Future<Response>
    func remove(request: Request, fileRecord: FileRecord) throws -> Future<Void>
    func uploadImage(request: Request, file: File, user: User) throws -> Future<User.Form>
}
