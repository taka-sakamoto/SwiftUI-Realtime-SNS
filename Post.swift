//
//  Post.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/04/30.
//

import Foundation

struct Post: Identifiable {
    let id: String
    let imageUrl: String
    let userId: String
    let userName: String
    let imagePath: String
    
    let caption: String
    
    let filterName: String?
    
    let createdAt: Date
    let likedBy: [String]
    
    var commentCount: Int
}
