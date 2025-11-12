//
//  MenuItemView.swift
//  RIT Dining
//
//  Created by Campbell on 11/6/25.
//

import SwiftUI

struct MenuItemView: View {
    @State var menuItem: FDMenuItem
    
    private var infoString: String {
        // Calories SHOULD always be available, so start there.
        var str = "\(menuItem.calories) Cal • "
        // Price might be $0.00, so don't display it if that's the case because that's obviously wrong. RIT Dining would never give
        // us free food!
        if menuItem.price == 0.0 {
            str += "Price Unavailable"
        } else {
            str += "$\(String(format: "%.2f", menuItem.price))"
        }
        // Same with the price, the serving size might be 0 which is also wrong so don't display that.
        if menuItem.servingSize != 0 {
            str += " • \(menuItem.servingSize) \(menuItem.servingSizeUnit)"
        }
        return str
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(menuItem.name)
                    .font(.title)
                    .fontWeight(.bold)
                Text(menuItem.category)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Text(infoString)
                .font(.title3)
                .foregroundStyle(.secondary)
                HStack {
                    ForEach(menuItem.dietaryMarkers, id: \.self) { dietaryMarker in
                        Text(dietaryMarker)
                            .foregroundStyle(Color.white)
                            .font(.caption)
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill({
                                        switch dietaryMarker {
                                        case "Vegan", "Vegetarian":
                                            return Color.green
                                        default:
                                            return Color.orange
                                        }
                                    }())
                            )
                    }
                }
                .padding(.bottom, 12)
                if !menuItem.allergens.isEmpty {
                    Text("Allergens")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(menuItem.allergens.joined(separator: ", "))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(.bottom, 12)
                }
                VStack(alignment: .leading) {
                    Text("Nutrition Facts")
                        .font(.title3)
                        .fontWeight(.semibold)
                    ForEach(menuItem.nutritionalEntries, id: \.self) { entry in
                        HStack(alignment: .top) {
                            Text(entry.type)
                            Spacer()
                            Text("\(String(format: "%.1f", entry.amount))\(entry.unit)")
                                .foregroundStyle(.secondary)
                        }
                        Divider()
                    }
                }
                .padding(.bottom, 12)
                Text("Ingredients")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(menuItem.ingredients)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MenuItemView(
        menuItem: FDMenuItem(
            id: 0,
            name: "Chocolate Chip Muffin",
            exactName: "Muffin Chocolate Chip Thaw and Serve A; Case; 72 Ounce; 12",
            category: "Baked Goods",
            allergens: ["Wheat", "Gluten", "Egg", "Milk", "Soy"],
            calories: 470,
            nutritionalEntries: [FDNutritionalEntry(type: "Example", amount: 0.0, unit: "g")],
            dietaryMarkers: ["Vegetarian"],
            ingredients: "Some ingredients that you'd expect to find inside of a chocolate chip muffin",
            price: 2.79,
            servingSize: 1,
            servingSizeUnit: "Each")
    )
}
