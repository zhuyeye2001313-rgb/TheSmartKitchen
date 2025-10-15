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
    var body: some View {
        singInForm()
    }
}

struct singInForm: View {
    
    @State var username = ""
    @State var password = ""
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack {
            Form {
                TextField(text: $username) {
                    Text("Username")
                }
                SecureField(text: $password) {
                    Text("Password")
                }
                
                Button("Submit") {
                    register()
                }
                .disabled(!isFormValid)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    func register() {
        Auth.auth().createUser(withEmail: username, password: password) { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("User registered successfully!")
            }
        }
    }
}


#Preview {
    ContentView()
}
