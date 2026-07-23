//
//  Date+Relative.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/07/23.
//

import Foundation

extension Date {
    
    func relativeString() -> String {
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        return formatter.localizedString(
            for: self,
            relativeTo: Date()
        )
    }
}
