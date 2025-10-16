//
//  TableView.swift
//  TheSmartKitchen
//
//  Created by 朱奕颖 on 2025/10/15.
//

import SwiftUI

struct TableView: View {
    var body: some View {
        Onboarding()
    }
}

struct Onboarding: View {
    @State var activeTab = 0
    
    var body: some View {
        TabView(selection: $activeTab){
            ZStack {
                Color.blue
                Text("Home").foregroundStyle(Color.white)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)
            
            ZStack {
                RecipeView()
            }
            .tabItem {
                Label("New Post", systemImage: "plus")
            }
            .tag(1)
            
            ZStack {
                Color.teal
                Text("New Post").foregroundStyle(Color.white)
            }
            .tabItem {
                Label("New Post", systemImage: "plus")
            }
            .tag(2)
            
            ZStack {
                UserView()
            }
            .tabItem {
                Label("Edit", systemImage: "pencil")
            }
            .tag(3)
            
        }
    }
}

#Preview {
    TableView()
}
