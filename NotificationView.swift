//
//  NotificationView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/09/29.
//

import SwiftUI

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    // @StateObject private var imageListViewModel = ImageListViewModel()
    // @Namespace private var namespace
    
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
                    /*
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            Task {
                                await viewModel.markAsRead(notification)
                            }
                        }
                    )
                     */
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
        for notificcation: AppNotification
    ) -> String {
        let senderName = viewModel.senderNames[notificcation.senderID] ?? ""
        
        switch notificcation.type {
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
