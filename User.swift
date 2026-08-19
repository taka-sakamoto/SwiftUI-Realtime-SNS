//
//  User.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/06/29.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    
    var id: String
    
    var displayName: String
    var bio: String
    var profileImageURL: String
    
    var followersCount: Int = 0
    var followingCount: Int = 0
    
    var createdAt: Date
    var updatedAt: Date
}
