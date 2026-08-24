//
//  FollowButton.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/19.
//

import SwiftUI

struct FollowButton: View {
    
    // MARK: - State
    
    enum State {
        case follow
        case following
        case followBack
    }
    
    let state: State
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Private
    
    private var title: String {
        switch state {
        case .follow:
            return "Follow"
        case.following:
            return "Following"
        case .followBack:
            return "Follow back"
        }
    }
}


/*
 #Preview {
 FollowButton()
 }
*/
