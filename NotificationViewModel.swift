//
//  NotificationViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/09/29.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    
    @Published var notifications: [AppNotification] = []
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchNotifications() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        do {
            let snapshot = try await db
                .collection("notifications")
                .whereField("recipientID", isEqualTo: currentUserID)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            
            notifications = snapshot.documents.compactMap { document in
                let data = document.data()
                
                guard
                    let recipientID = data["recipientID"] as? String,
                    let senderID = data["senderID"] as? String,
                    let typeRawValue = data["type"] as? String,
                    let type = NotificationType(rawValue: typeRawValue),
                    let createdAt = data["createdAt"] as? Timestamp,
                    let isRead = data["isRead"] as? Bool
                else {
                    return nil
                }
                
                return AppNotification(
                    id: document.documentID,
                    recipientID: recipientID,
                    senderID: senderID,
                    type: type,
                    postID: data["postID"] as? String,
                    createdAt: createdAt.dateValue(),
                    isRead: isRead
                )
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
