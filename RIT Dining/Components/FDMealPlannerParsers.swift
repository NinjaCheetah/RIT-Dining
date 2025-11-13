//
//  FDMealPlannerParsers.swift
//  RIT Dining
//
//  Created by Campbell on 11/3/25.
//

import Foundation

func parseFDMealPlannerMenu(menu: FDMealsParser) -> [FDMenuItem] {
    var menuItems: [FDMenuItem] = []
    if menu.result.isEmpty {
        return menuItems
    }
    // We only need to operate on index 0, because the request code is designed to only get the menu for a single day so there
    // will only be a single index to operate on.
    if let allMenuRecipes = menu.result[0].allMenuRecipes {
        for recipe in allMenuRecipes {
            // Prevent duplicate items from being added, because for some reason the exact same item with the exact same information
            // might be included in FD MealPlanner more than once.
            if menuItems.contains(where: { $0.id == recipe.componentId }) {
                continue
            }
            // englishAlternateName holds the proper name of the item, but it's blank for some items for some reason. If that's the
            // case, then we should fall back on componentName, which is less user-friendly but works as a backup.
            let realName = if recipe.englishAlternateName != "" {
                recipe.englishAlternateName.trimmingCharacters(in: .whitespaces)
            } else {
                recipe.componentName.trimmingCharacters(in: .whitespaces)
            }
            let allergens = recipe.allergenName != "" ? recipe.allergenName.components(separatedBy: ",") : []
            // Get the list of dietary markers (Vegan, Vegetarian, Pork, Beef), and drop "Vegetarian" if "Vegan" is also included since
            // that's kinda redundant.
            var dietaryMarkers = recipe.recipeProductDietaryName != "" ? recipe.recipeProductDietaryName.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } : []
            if dietaryMarkers.contains("Vegan") {
                dietaryMarkers.remove(at: dietaryMarkers.firstIndex(of: "Vegetarian")!)
            }
            let calories = Int(Double(recipe.calories)!.rounded())
            // Collect and organize all the nutritional entries. I ordered them based off how they were ordered in the nutritional
            // facts panel on the side of the bag of goldfish that lives on my desk, so presumably they're ordered correctly.
            let nutritionalEntries = [
                FDNutritionalEntry(type: "Total Fat", amount: Double(recipe.fat) ?? 0.0, unit: recipe.fatUOM),
                FDNutritionalEntry(type: "Saturated Fat", amount: Double(recipe.saturatedFat) ?? 0.0, unit: recipe.saturatedFatUOM),
                FDNutritionalEntry(type: "Trans Fat", amount: Double(recipe.transFattyAcid) ?? 0.0, unit: recipe.transFattyAcidUOM),
                FDNutritionalEntry(type: "Cholesterol", amount: Double(recipe.cholesterol) ?? 0.0, unit: recipe.cholesterolUOM),
                FDNutritionalEntry(type: "Sodium", amount: Double(recipe.sodium) ?? 0.0, unit: recipe.sodiumUOM),
                FDNutritionalEntry(type: "Total Carbohydrates", amount: Double(recipe.carbohydrates) ?? 0.0, unit: recipe.carbohydratesUOM),
                FDNutritionalEntry(type: "Dietary Fiber", amount: Double(recipe.dietaryFiber) ?? 0.0, unit: recipe.dietaryFiberUOM),
                FDNutritionalEntry(type: "Total Sugars", amount: Double(recipe.totalSugars) ?? 0.0, unit: recipe.totalSugarsUOM),
                FDNutritionalEntry(type: "Protein", amount: Double(recipe.protein) ?? 0.0, unit: recipe.proteinUOM),
                FDNutritionalEntry(type: "Calcium", amount: Double(recipe.calcium) ?? 0.0, unit: recipe.calciumUOM),
                FDNutritionalEntry(type: "Iron", amount: Double(recipe.iron) ?? 0.0, unit: recipe.ironUOM),
                FDNutritionalEntry(type: "Vitamin A", amount: Double(recipe.vitaminA) ?? 0.0, unit: recipe.vitaminAUOM),
                FDNutritionalEntry(type: "Vitamin C", amount: Double(recipe.vitaminC) ?? 0.0, unit: recipe.vitaminCUOM),
            ]
            
            let newItem = FDMenuItem(
                id: recipe.componentId,
                name: realName,
                exactName: recipe.componentName,
                category: recipe.category,
                allergens: allergens,
                calories: calories,
                nutritionalEntries: nutritionalEntries,
                dietaryMarkers: dietaryMarkers,
                ingredients: recipe.ingredientStatement,
                price: recipe.sellingPrice,
                servingSize: recipe.productMeasuringSize,
                servingSizeUnit: recipe.productMeasuringSizeUnit
            )
            menuItems.append(newItem)
        }
    }
    return menuItems
}
