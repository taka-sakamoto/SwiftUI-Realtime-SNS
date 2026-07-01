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
    
    var createdAt: Date
    var updatedAt: Date
}
