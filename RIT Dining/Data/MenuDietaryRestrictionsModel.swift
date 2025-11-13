//
//  MenuDietaryRestrictionsModel.swift
//  RIT Dining
//
//  Created by Campbell on 11/11/25.
//

import SwiftUI

class MenuDietaryRestrictionsModel: ObservableObject {
    var dietaryRestrictions = DietaryRestrictions()
    @AppStorage("isVegetarian") var isVegetarian: Bool = false
    @AppStorage("isVegan") var isVegan: Bool = false
    @AppStorage("noBeef") var noBeef: Bool = false
    @AppStorage("noPork") var noPork: Bool = false
}
