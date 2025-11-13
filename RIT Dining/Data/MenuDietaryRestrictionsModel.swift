//
//  MenuDietaryRestrictionsModel.swift
//  RIT Dining
//
//  Created by Campbell on 11/11/25.
//

import SwiftUI

class MenuDietaryRestrictionsModel: ObservableObject {
    var dietaryRestrictions = DietaryRestrictions()
    
    // I thought these could be @AppStorage keys but apparently not, because SwiftUI would subscribe to updates from those if
    // they aren't being used directly inside the view.
    @Published var isVegetarian: Bool {
        didSet { UserDefaults.standard.set(isVegetarian, forKey: "isVegetarian") }
    }

    @Published var isVegan: Bool {
        didSet { UserDefaults.standard.set(isVegan, forKey: "isVegan") }
    }

    @Published var noBeef: Bool {
        didSet { UserDefaults.standard.set(noBeef, forKey: "noBeef") }
    }

    @Published var noPork: Bool {
        didSet { UserDefaults.standard.set(noPork, forKey: "noPork") }
    }

    init() {
        self.isVegetarian = UserDefaults.standard.bool(forKey: "isVegetarian")
        self.isVegan = UserDefaults.standard.bool(forKey: "isVegan")
        self.noBeef = UserDefaults.standard.bool(forKey: "noBeef")
        self.noPork = UserDefaults.standard.bool(forKey: "noPork")
    }
}
