//
//  FDMealPlannerTypes.swift
//  RIT Dining
//
//  Created by Campbell on 11/3/25.
//

import Foundation

/// Struct to parse the response from the FDMP search API. This API returns all of the dining locations that are have menus available and the required IDs needed to get those menus.
struct FDSearchResponseParser: Decodable {
    /// The main response body containing the result count and the results themselves.
    struct Data: Decodable {
        /// The key information returned for each location in the search results. These values are required to pass along to the menu API.
        struct Result: Decodable {
            let locationId: Int
            let accountId: Int
            let tenantId: Int
            let locationName: String
            let locationCode: String
            let locationDisplayName: String
            let accountName: String
        }
        let result: [Result]
        let totalCount: Int
    }
    let success: Bool
    let errorMessage: String?
    let data: Data
}

/// Struct to parse the response from the FDMP meal periods API. This API returns all potentail meal periods for a location based on its ID. This meal period ID is required to get the menu for that meal period from the meals API.
struct FDMealPeriodsParser: Decodable {
    /// The response body, which is a list of responses that include a meal period and the ID that maps to it.
    struct Data: Decodable {
        let id: Int
        let mealPeriodName: String
    }
    let success: Bool
    let errorMessage: String?
    let data: [Data]
}

/// Struct to parse the response from the FDMP meals API. This API contains the actual menu information for the specified location during the specified meal period. It doesn't contain every menu item, but it's the best source of menu information that I can access.
struct FDMealsParser: Decodable, Hashable {
    /// The actual response body.
    struct Result: Decodable, Hashable {
        /// An individual item on the menu at this location and its information.
        struct MenuRecipe: Decodable, Hashable {
            let componentName: String
            let componentId: Int
            let componentTypeId: Int
            let englishAlternateName: String
            let category: String
            let allergenName: String
            let calories: String
            let recipeProductDietaryName: String
            let ingredientStatement: String
            let sellingPrice: Double
            let productMeasuringSize: Int
            let productMeasuringSizeUnit: String
            let itemsToOrder: Int
        }
        let menuId: Int
        let menuForDate: String
        let menuToDate: String
        let accountId: Int
        let accountName: String
        let menuTypeName: String
        let mealPeriodId: Int
        let allMenuRecipes: [MenuRecipe]?
    }
    let responseStatus: String?
    let result: [Result]
}

/// A single menu item, stripped down and reorganized to a format that actually makes sense for me to use in the rest of the app.
struct FDMenuItem: Hashable, Identifiable {
    let id: Int
    let name: String
    let exactName: String
    let category: String
    let allergens: [String]
    let calories: Int
    let dietaryMarkers: [String]
    let ingredients: String
    let price: Double
    let servingSize: Int
    let servingSizeUnit: String
}
