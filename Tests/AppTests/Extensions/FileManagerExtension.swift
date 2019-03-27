//
//  FileManagerExtension.swift
//  AppTests
//
//  Created by Timur Shafigullin on 27/03/2019.
//

import Foundation

extension FileManager {

    // MARK: - Instance Methods

    func copyItemIfNeeded(at srcURL: URL, to dstURL: URL) throws {
        guard !FileManager.default.fileExists(atPath: dstURL.path) else {
            return
        }
        
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
    }
}
