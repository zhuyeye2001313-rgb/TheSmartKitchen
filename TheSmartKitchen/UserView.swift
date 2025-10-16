//
//  UserView.swift
//  TheSmartKitchen
//
//  Created by 朱奕颖 on 2025/10/15.
//
//111
import SwiftUI
import Firebase
import FirebaseAuth

struct UserView: View {
    @State private var userEmail = ""
    @State private var userName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Profile Header
                    VStack(spacing: 20) {
                        // Profile Picture Placeholder
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        // User Info
                        VStack(spacing: 8) {
                            Text(userName.isEmpty ? "Smart Kitchen User" : userName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Options
                    VStack(spacing: 16) {
                        ProfileOptionRow(
                            icon: "person.circle.fill",
                            title: "Personal Information",
                            subtitle: "Update your profile details",
                            iconColor: .blue
                        )
                        
                        ProfileOptionRow(
                            icon: "bell.fill",
                            title: "Notifications",
                            subtitle: "Manage your notification settings",
                            iconColor: .orange
                        )
                        
                        ProfileOptionRow(
                            icon: "lock.fill",
                            title: "Privacy & Security",
                            subtitle: "Control your privacy settings",
                            iconColor: .green
                        )
                        
                        ProfileOptionRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            subtitle: "Get help and contact support",
                            iconColor: .purple
                        )
                        
                        ProfileOptionRow(
                            icon: "info.circle.fill",
                            title: "About",
                            subtitle: "App version and information",
                            iconColor: .gray
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Logout Button
                    Button(action: {
                        // Logout action will be handled by parent view
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadUserInfo()
            }
        }
    }
    
    private func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            userEmail = user.email ?? "No email available"
            
            // Extract name from email (part before @)
            if let email = user.email {
                let namePart = String(email.split(separator: "@").first ?? "")
                userName = namePart.capitalized
            }
        }
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    UserView()
}
