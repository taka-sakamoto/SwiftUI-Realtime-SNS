//
//  NotificationView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/09/29.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()

    @ObservedObject var imageListViewModel: ImageListViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    let namespace: Namespace.ID
    
    var body: some View {
        List {
            ForEach(viewModel.notifications, id: \.id) { notification in
                if notification.type == .follow {
                    NavigationLink {
                        ProfileView(
                            viewModel: profileViewModel,
                            imageListViewModel: imageListViewModel,
                            namespace: namespace,
                            userID: notification.senderID,
                            onLogout: {
                                // 通知画面からはログアウトしない
                            }
                        )
                        .task {
                            await viewModel.markAsRead(notification)
                        }
                    } label: {
                        notificationRow(for: notification)
                    }
                    
                } else if let postID = notification.postID,
                          let post = imageListViewModel.posts.first(where: {
                              $0.id == postID
                          }) {
                    NavigationLink {
                        PostDetailView(
                            post: post,
                            namespace: namespace,
                            onClose: {
                                // 詳細画面を閉じる処理は既存実装に合わせる
                            }, viewModel: imageListViewModel
                        )
                        .task {
                            await viewModel.markAsRead(notification)
                        }
                    } label: {
                        notificationRow(for: notification)
                    }
                } else {
                    notificationRow(for: notification)
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await viewModel.fetchNotifications()
        }
    }
        
    private func notificationRow(
        for notification: AppNotification
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(notificationMessage(for: notification))
                    .font(.body)

                Text(notification.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private func notificationMessage(
        for notification: AppNotification
    ) -> String {
        let senderName = viewModel.senderNames[notification.senderID] ?? ""
        
        switch notification.type {
        case .follow:
            return "\(senderName)さんがあなたをフォローしました"
            
        case .like:
            return "\(senderName)さんがあなたの投稿にいいねしました"
            
        case .comment:
            return "\(senderName)さんがあなたの投稿にコメントしました"
        }
    }
}


/*
#Preview {
    NotificationView()
}
*/
