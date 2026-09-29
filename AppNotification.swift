//
//  AppNotification.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/09/25.
//

import Foundation

struct AppNotification: Identifiable {
    let id: String
    let recipientID: String
    let senderID: String
    let type: NotificationType
    let postID: String?
    let createdAt: Date
    var isRead: Bool
}

enum NotificationType: String {
    case follow
    case like
    case comment
}
