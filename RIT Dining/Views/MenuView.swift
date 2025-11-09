//
//  MenuView.swift
//  RIT Dining
//
//  Created by Campbell on 11/3/25.
//

import SwiftUI

struct MenuView: View {
    @State var accountId: Int
    @State var locationId: Int
    @State private var menuItems: [FDMenuItem] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @State private var rotationDegrees: Double = 0
    @State private var selectedMealPeriod: Int = 0
    @State private var openPeriods: [Int] = []
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    func getOpenPeriods() async {
        // Only run this if we haven't already gotten the open periods. This is somewhat of a bandaid solution to the issue of
        // fetching this information more than once, but hey it works!
        if openPeriods.isEmpty {
            switch await getFDMealPlannerOpenings(locationId: locationId) {
            case .success(let openingResults):
                openPeriods = openingResults.data.map { Int($0.id) }
                selectedMealPeriod = openPeriods[0]
                // Since this only runs once when the view first loads, we can safely use this to call the method to get the data
                // the first time. This also ensures that it doesn't happen until we have the opening periods collected.
                await getMenuForPeriod(mealPeriodId: selectedMealPeriod)
            case .failure(let error):
                print(error)
                loadFailed = true
            }
        }
    }
    
    func getMenuForPeriod(mealPeriodId: Int) async {
        switch await getFDMealPlannerMenu(locationId: locationId, accountId: accountId, mealPeriodId: mealPeriodId) {
        case .success(let menus):
            menuItems = parseFDMealPlannerMenu(menu: menus)
            isLoading = false
        case .failure(let error):
            print(error)
            loadFailed = true
        }
    }
    
    func getPriceString(price: Double) -> String {
        if price == 0.0 {
            return "Price Unavailable"
        } else {
            return "$\(String(format: "%.2f", price))"
        }
    }
    
    private var filteredMenuItems: [FDMenuItem] {
        var newItems = menuItems
        newItems = newItems.filter { item in
            let searchedLocations = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            return searchedLocations
        }
        return newItems
    }
    
    var body: some View {
        if isLoading {
            VStack {
                if loadFailed {
                    Image(systemName: "wifi.exclamationmark.circle")
                        .resizable()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(.accent)
                    Text("An error occurred while fetching the menu. Please check your network connection and try again.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "fork.knife.circle")
                        .resizable()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(.accent)
                        .rotationEffect(.degrees(rotationDegrees))
                        .onAppear {
                            withAnimation(animation) {
                                rotationDegrees = 360.0
                            }
                        }
                    Text("One moment...")
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                await getOpenPeriods()
            }
            .padding()
        } else {
            VStack {
                if !menuItems.isEmpty {
                    List {
                        Section {
                            ForEach(filteredMenuItems) { item in
                                NavigationLink(destination: MenuItemView(menuItem: item)) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(item.name)
                                            ForEach(item.dietaryMarkers, id: \.self) { dietaryMarker in
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
                                        Text("\(item.calories) Cal • \(getPriceString(price: item.price))")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Menu")
                    .navigationBarTitleDisplayMode(.large)
                    .searchable(text: $searchText, prompt: "Search")
                } else {
                    Image(systemName: "clock.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(.accent)
                    Text("No menu is available for the selected meal period today. Try selecting a different meal period.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Meal Period", selection: $selectedMealPeriod) {
                            ForEach(openPeriods, id: \.self) { period in
                                Text(fdmpMealPeriodsMap[period]!).tag(period)
                            }
                        }
                    } label: {
                        Image(systemName: "clock")
                    }
                }
            }
            .onChange(of: selectedMealPeriod) {
                rotationDegrees = 0
                isLoading = true
                Task {
                    await getMenuForPeriod(mealPeriodId: selectedMealPeriod)
                }
            }
        }
    }
}

#Preview {
    MenuView(accountId: 1, locationId: 1)
}
