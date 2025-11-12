//
//  MenuDietaryRestrictionsModel.swift
//  RIT Dining
//
//  Created by Campbell on 11/11/25.
//

import SwiftUI

@Observable
class MenuDietaryRestrictionsModel {
    var filteredDietaryMarkers: Set<String> = []
    var dietaryRestrictions = DietaryRestrictions()
    var isVegetarian: Bool = false
    var isVegan: Bool = false
}
