//
//  DietaryRestrictions.swift
//  RIT Dining
//
//  Created by Campbell on 11/11/25.
//

import SwiftUI

enum Allergen: String, Codable, CaseIterable {
    case coconut
    case egg
    case gluten
    case milk
    case peanut
    case sesame
    case shellfish
    case soy
    case treenut
    case wheat
}

@Observable
class DietaryRestrictions {
    private var dietaryRestrictions: Set<String>
    private let key = "DietaryRestrictions"

    init() {
        let favorites = UserDefaults.standard.array(forKey: key) as? [String] ?? [String]()
        dietaryRestrictions = Set(favorites)
    }

    func contains(_ restriction: Allergen) -> Bool {
        dietaryRestrictions.contains(restriction.rawValue)
    }

    func add(_ restriction: Allergen) {
        dietaryRestrictions.insert(restriction.rawValue)
        save()
    }

    func remove(_ restriction: Allergen) {
        dietaryRestrictions.remove(restriction.rawValue)
        save()
    }

    func save() {
        let favorites = Array(dietaryRestrictions)
        UserDefaults.standard.set(favorites, forKey: key)
    }
}
