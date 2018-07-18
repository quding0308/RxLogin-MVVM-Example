//
//  Person.swift
//  DZDemo
//
//  Created by Darren Zheng on 2018/7/18.
//  Copyright © 2018 Darren Zheng. All rights reserved.
//

class Person: Codable {
    var username: String?
    var password: String?
    init(username: String?, password: String?) {
        self.username = username
        self.password = password
    }
}
