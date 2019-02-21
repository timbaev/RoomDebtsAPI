//
//  UserService.swift
//  App
//
//  Created by Timur Shafigullin on 11/02/2019.
//

import Vapor

protocol UserService {
    
    // MARK: - Instance Methods
    
    func search(request: Request, keyword: String) -> Future<[User.SearchForm]>
}
