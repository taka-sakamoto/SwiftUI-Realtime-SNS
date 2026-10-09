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
    @Published var senderNames: [String: String] = [:]
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let userRepository = UserRepository()
    
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
            
            senderNames = [:]
            
            for notification in notifications {
                guard senderNames[notification.senderID] == nil else {
                    continue
                }
                
                do {
                    let user = try await userRepository.fetchUser(
                        uid: notification.senderID
                    )
                    senderNames[notification.senderID] = user.displayName
                } catch {
                    senderNames[notification.senderID] = ""
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func markAsRead(_ notification: AppNotification) async {
        print("markAsRead called:", notification.id)  // ログ用
        print("isRead before:", notification.isRead)  // ログ用
        
        // すでに既読なら何もしない
        guard !notification.isRead else {
            print("Already read")  // ログ用
            return
        }
        
        do {
            try await db
                .collection("notifications")
                .document(notification.id)
                .updateData(["isRead": true])
            
            print("Firestore update succeeded")  // ログ用
            
            if let index = notifications.firstIndex(where: {
                $0.id == notification.id
            }) {
                notifications[index].isRead = true
                print("Local notification updated")  // ログ用
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Firestore update failed:", error.localizedDescription)  // ログ用
        }
    }
    
    
}
