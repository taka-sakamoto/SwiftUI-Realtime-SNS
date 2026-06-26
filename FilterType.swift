//
//  FilterType.swift
//  MetalFirebaseApp
//
//  Created by Takayuki Sakamoto on 2026/05/22.
//

import Foundation

enum FilterType: String, CaseIterable {
    case normal
    case sepia
    case mono
    case invert
    
    var hasIntensity: Bool {
        switch self {
        case .mono, .sepia:
            return true
        default:
            return false
        }
    }
}
