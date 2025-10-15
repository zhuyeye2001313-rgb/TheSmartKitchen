//
//  ContentView.swift
//  TheSmartKitchen
//
//  Created by 朱奕颖 on 2025/10/15.
//

import SwiftUI
import Firebase
import FirebaseAuth



struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var userIsLoggedIn = false

    var body: some View {
        if userIsLoggedIn {
            TableView()
        } else {
            content
        }
    }
    
    var content: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Sign Up") {
                register()
            }
            .padding()
        }
        .onAppear {
            try? Auth.auth().signOut()
            Auth.auth().addStateDidChangeListener { _, user in
                userIsLoggedIn = (user != nil)
            }
        }
    }

    func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else {
                print("User registered successfully: \(result?.user.uid ?? "")")
            }
        }
    }
}

#Preview {
    ContentView()
}
