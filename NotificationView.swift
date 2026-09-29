//
//  NotificationView.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/09/29.
//

import SwiftUI

struct NotificationView: View {
    
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        List(viewModel.notifications) { notification in
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
        .navigationTitle("Notifications")
        .task {
            await viewModel.fetchNotifications()
        }
    }
    
    private func notificationMessage(
        for notificcation: AppNotification
    ) -> String {
        switch notificcation.type {
        case .follow:
            return "フォローされました"
            
        case .like:
            return "あなたの投稿にいいねされました"
            
        case .comment:
            return "あなたの投稿にコメントされました"
        }
    }
}


/*
#Preview {
    NotificationView()
}
*/
