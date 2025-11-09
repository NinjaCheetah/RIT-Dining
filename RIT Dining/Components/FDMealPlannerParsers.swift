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
            // englishAlternateName holds the proper name of the item, but it's blank for some items for some reason. If that's the
            // case, then we should fall back on componentName, which is less user-friendly but works as a backup.
            let realName = if recipe.englishAlternateName != "" {
                recipe.englishAlternateName
            } else {
                recipe.componentName
            }
            let allergens = recipe.allergenName.components(separatedBy: ",")
            // Get the list of dietary markers (Vegan, Vegetarian, Pork, Beef), and drop "Vegetarian" if "Vegan" is also included since
            // that's kinda redundant.
            var dietaryMarkers = recipe.recipeProductDietaryName != "" ? recipe.recipeProductDietaryName.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } : []
            if dietaryMarkers.contains("Vegan") {
                dietaryMarkers.remove(at: dietaryMarkers.firstIndex(of: "Vegetarian")!)
            }
            let calories = Int(Double(recipe.calories)!.rounded())
            
            let newItem = FDMenuItem(
                id: recipe.componentId,
                name: realName,
                exactName: recipe.componentName,
                category: recipe.category,
                allergens: allergens,
                calories: calories,
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
