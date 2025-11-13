//
//  MenuDietaryRestrictionsSheet.swift
//  RIT Dining
//
//  Created by Campbell on 11/11/25.
//

import SwiftUI

struct MenuDietaryRestrictionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var dietaryRestrictionsModel: MenuDietaryRestrictionsModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Diet")) {
                    Toggle(isOn: $dietaryRestrictionsModel.noBeef) {
                        Text("No Beef")
                    }
                    Toggle(isOn: $dietaryRestrictionsModel.noPork) {
                        Text("No Pork")
                    }
                    Toggle(isOn: $dietaryRestrictionsModel.isVegetarian) {
                        Text("Vegetarian")
                    }
                    Toggle(isOn: $dietaryRestrictionsModel.isVegan) {
                        Text("Vegan")
                    }
                }
                Section(header: Text("Allergens")) {
                    ForEach(Allergen.allCases, id: \.self) { allergen in
                        Toggle(isOn: Binding(
                            get: {
                                dietaryRestrictionsModel.dietaryRestrictions.contains(allergen)
                            },
                            set: { isOn in
                                if isOn {
                                    dietaryRestrictionsModel.dietaryRestrictions.add(allergen)
                                } else {
                                    dietaryRestrictionsModel.dietaryRestrictions.remove(allergen)
                                }
                            }
                        )) {
                            Text(allergen.rawValue.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("Menu Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}
