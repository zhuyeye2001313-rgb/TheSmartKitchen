//
//  TheSmartKitchenApp.swift
//  TheSmartKitchen
//
//  Created by 朱奕颖 on 2025/10/15.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct TheSmartKitchenApp: App {
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Optional: Disable Analytics collection if you don't need it
        // This can help resolve the CA Event error
        // Analytics.setAnalyticsCollectionEnabled(false)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

