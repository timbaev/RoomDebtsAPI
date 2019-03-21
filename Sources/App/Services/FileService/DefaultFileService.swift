//
//  DefaultFileService.swift
//  App
//
//  Created by Timur Shafigullin on 02/02/2019.
//

import Vapor
import Crypto

class DefaultFileService: FileService {
    
    // MARK: - Instance Methods
    
    func download(request: Request, fileRecord: FileRecord) throws -> Future<Response> {
        let workDir = DirectoryConfig.detect().workDir
        let filePath = workDir + fileRecord.localPath
        
        var isDir: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            throw Abort(.notFound)
        }
        
        return try request.streamFile(at: filePath)
    }
    
    func remove(request: Request, fileRecord: FileRecord) throws -> Future<Void> {
        let workDir = DirectoryConfig.detect().workDir
        let filePath = workDir + fileRecord.localPath
        
        var isDir: ObjCBool = false
        
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            throw Abort(.notFound)
        }
        
        try FileManager.default.removeItem(atPath: filePath)
        
        return fileRecord.delete(on: request).transform(to: ())
    }
    
    func uploadImage(request: Request, file: File, user: User) throws -> Future<User.Form> {
        let workDir = DirectoryConfig.detect().workDir
        let fileStorage = Environment.STORAGE_PATH.convertToPathComponents().readable + "/" + (file.ext ?? "other")
        let path = URL(fileURLWithPath: workDir).appendingPathComponent(fileStorage, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: path.absoluteString) {
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        let key = try CryptoRandom().generateData(count: 16).base64URLEncodedString()
        let encodedFilename = key + "." + (file.ext ?? "")
        let writePath = path.appendingPathComponent(encodedFilename, isDirectory: false)
        
        try file.data.write(to: writePath, options: .withoutOverwriting)
        
        let localPath = fileStorage + "/" + encodedFilename
        
        return FileRecord(filename: file.filename, fileKind: file.ext, localPath: localPath).save(on: request).flatMap { fileRecord in
            user.imageID = try fileRecord.requireID()
            return user.save(on: request).toForm()
        }
    }
}
