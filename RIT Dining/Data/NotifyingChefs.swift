//
//  NotifyingChefs.swift
//  RIT Dining
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

@Observable
class NotifyingChefs {
    private var notifyingChefs: Set<String>
    private let key = "NotifyingChefs"

    init() {
        let chefs = UserDefaults.standard.array(forKey: key) as? [String] ?? [String]()
        notifyingChefs = Set(chefs)
    }

    func contains(_ chef: String) -> Bool {
        notifyingChefs.contains(chef.lowercased())
    }

    func add(_ chef: String) {
        notifyingChefs.insert(chef.lowercased())
        save()
    }

    func remove(_ chef: String) {
        notifyingChefs.remove(chef.lowercased())
        save()
    }

    func save() {
        let chefs = Array(notifyingChefs)
        UserDefaults.standard.set(chefs, forKey: key)
    }
}
