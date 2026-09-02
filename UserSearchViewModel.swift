//
//  UserSearchViewModel.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/08/28.
//

import Foundation
import Combine

@MainActor
final class UserSearchViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var searchText = ""
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository = UserRepository()
    
    // MARK: - Methods
    
    func searchUsers() async {
        
        let keyword = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !keyword.isEmpty else {
            users = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            users = try await repository.searchUsers(keyword: keyword)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
