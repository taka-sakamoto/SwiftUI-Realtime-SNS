//
//  Comment.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/18.
//

import Foundation

struct Comment: Identifiable {
    
    let id: String
    let text: String
    let userId: String
    let userName: String
    let profileImageURL: String
    let createdAt: Date
}
