//
//  Favorites.swift
//  RIT Dining
//
//  Created by Campbell on 9/22/25.
//

import SwiftUI

@Observable
class Favorites {
    private var favoriteLocations: Set<Int>
    private let key = "Favorites"

    init() {
        let favorites = UserDefaults.standard.array(forKey: key) as? [Int] ?? [Int]()
        favoriteLocations = Set(favorites)
    }

    func contains(_ location: DiningLocation) -> Bool {
        favoriteLocations.contains(location.id)
    }

    func add(_ location: DiningLocation) {
        favoriteLocations.insert(location.id)
        save()
    }

    func remove(_ location: DiningLocation) {
        favoriteLocations.remove(location.id)
        save()
    }

    func save() {
        let favorites = Array(favoriteLocations)
        UserDefaults.standard.set(favorites, forKey: key)
    }
}
