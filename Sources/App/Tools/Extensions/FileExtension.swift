//
//  FileExtension.swift
//  App
//
//  Created by Timur Shafigullin on 27/03/2019.
//

import Vapor

extension File {

    // MARK: - Instance Properties

    var `extension`: String? {
        let splitted = self.filename.split(separator: ".")

        if splitted.count > 1 {
            return splitted.last.map(String.init)
        } else {
            return nil
        }
    }
}
