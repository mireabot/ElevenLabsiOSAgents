//
//  User.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/23/25.
//

import Foundation

struct User {
    let id: UUID
    let name: String
    let isPremium: Bool
    
    init(id: UUID = UUID(), name: String, isPremium: Bool = false) {
        self.id = id
        self.name = name
        self.isPremium = isPremium
    }
    
    static let demo = User(name: "Michael", isPremium: true)
}