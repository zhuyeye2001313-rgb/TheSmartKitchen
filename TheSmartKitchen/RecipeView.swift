//
//  RecipeView.swift
//  TheSmartKitchen
//
//  Created by 朱奕颖 on 2025/10/15.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

// Recipe data model
struct Recipe: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let ingredients: [String]
    let steps: [String]
    let userId: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, category: String, ingredients: [String], steps: [String], userId: String = Auth.auth().currentUser?.uid ?? "") {
        self.id = id
        self.name = name
        self.category = category
        self.ingredients = ingredients
        self.steps = steps
        self.userId = userId
        self.createdAt = Date()
    }
}

// Firebase Recipe Service
class RecipeService {
    private let db = Firestore.firestore()
    
    func saveRecipe(_ recipe: Recipe) async throws {
        let recipeData: [String: Any] = [
            "name": recipe.name,
            "category": recipe.category,
            "ingredients": recipe.ingredients,
            "steps": recipe.steps,
            "userId": recipe.userId,
            "createdAt": recipe.createdAt
        ]
        
        try await db.collection("recipes").document(recipe.id).setData(recipeData)
    }
    
    func loadRecipes() async throws -> [Recipe] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "RecipeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let snapshot = try await db.collection("recipes")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let recipes = snapshot.documents.compactMap { document in
            try? document.data(as: Recipe.self)
        }
        
        // Sort locally by creation date (newest first)
        return recipes.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteRecipe(_ recipe: Recipe) async throws {
        try await db.collection("recipes").document(recipe.id).delete()
    }
}

struct RecipeView: View {
    @State private var recipeService = RecipeService()
    @State private var showingAddRecipe = false
    @State private var recipes: [Recipe] = []
    @State private var selectedRecipe: Recipe?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header with title and plus button
                HStack {
                    Text("Recipes")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddRecipe = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    Text("Search recipes")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                
                // Recipe List
                if isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading recipes...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if recipes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No recipes yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Tap the + button to add your first recipe")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(recipes) { recipe in
                                Button(action: {
                                    selectedRecipe = recipe
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text(recipe.category)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("Created: \(recipe.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddRecipe) {
            AddRecipeView(showingAddRecipe: $showingAddRecipe, onRecipeSaved: { recipe in
                Task {
                    await saveRecipe(recipe)
                }
            })
        }
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await loadRecipes()
            }
        }
    }
    
    // MARK: - Firebase Functions
    
    private func loadRecipes() async {
        isLoading = true
        do {
            let loadedRecipes = try await recipeService.loadRecipes()
            await MainActor.run {
                self.recipes = loadedRecipes
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load recipes: \(error.localizedDescription)"
                self.showingError = true
                self.isLoading = false
            }
        }
    }
    
    private func saveRecipe(_ recipe: Recipe) async {
        do {
            try await recipeService.saveRecipe(recipe)
            await MainActor.run {
                self.recipes.insert(recipe, at: 0) // Add to beginning of list
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save recipe: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
}

struct AddRecipeView: View {
    @Binding var showingAddRecipe: Bool
    let onRecipeSaved: (Recipe) -> Void
    
    @State private var recipeName = ""
    @State private var category = "Dinner"
    @State private var ingredients: [String] = [""]
    @State private var steps: [String] = [""]
    
    let categories = ["Dinner", "Lunch", "Breakfast"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Info")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 16) {
                            TextField("Recipe Name", text: $recipeName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                Text("Category")
                                Spacer()
                                Picker("Category", selection: $category) {
                                    ForEach(categories, id: \.self) { category in
                                        Text(category).tag(category)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(ingredients.indices, id: \.self) { index in
                                TextField("Ingredient name and amount", text: $ingredients[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Button(action: {
                                ingredients.append("")
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .foregroundColor(.orange)
                                    Text("+ingredient")
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    
                    // Cooking Steps Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cooking Steps")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            ForEach(steps.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Step \(index + 1)")
                                        .font(.headline)
                                    
                                    TextField("Type your step here...", text: $steps[index], axis: .vertical)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(3...6)
                                }
                            }
                            
                            Button(action: {
                                steps.append("")
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .foregroundColor(.orange)
                                    Text("Add Step")
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    
                    // Save Recipe Button
                    Button(action: {
                        let newRecipe = Recipe(
                            name: recipeName,
                            category: category,
                            ingredients: ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                            steps: steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                        )
                        onRecipeSaved(newRecipe)
                        showingAddRecipe = false
                    }) {
                        Text("Save Recipe")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.orange : Color.gray)
                            .cornerRadius(12)
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddRecipe = false
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !recipeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ingredients.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } &&
        !steps.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recipe Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(recipe.category)
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.ingredients.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.orange)
                                        .fontWeight(.bold)
                                    Text(recipe.ingredients[index])
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // Cooking Steps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cooking Steps")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(recipe.steps.indices, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Step \(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    
                                    Text(recipe.steps[index])
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.leading, 8)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("Recipe Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    RecipeView()
}

#Preview("Recipe Detail") {
    RecipeDetailView(recipe: Recipe(
        name: "Sample Recipe",
        category: "Dinner",
        ingredients: ["2 cups flour", "1 cup sugar", "3 eggs"],
        steps: ["Mix dry ingredients", "Add wet ingredients", "Bake for 30 minutes"]
    ))
}
