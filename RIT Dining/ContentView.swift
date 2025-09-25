//
//  ContentView.swift
//  RIT Dining
//
//  Created by Campbell on 8/31/25.
//

import SwiftUI

struct ContentView: View {
    // Save sort/filter options in AppStorage so that they actually get saved.
    @AppStorage("openLocationsOnly") var openLocationsOnly: Bool = false
    @AppStorage("openLocationsFirst") var openLocationsFirst: Bool = false
    @State private var favorites = Favorites()
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @State private var showingDonationSheet: Bool = false
    @State private var rotationDegrees: Double = 0
    @State private var diningLocations: [DiningLocation] = []
    @State private var lastRefreshed: Date?
    @State private var searchText: String = ""
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    // Asynchronously fetch the data for all of the locations and parse their data to display it.
    private func getDiningData() async {
        var newDiningLocations: [DiningLocation] = []
        getAllDiningInfo(date: nil) { result in
            switch result {
            case .success(let locations):
                for i in 0..<locations.locations.count {
                    let diningInfo = parseLocationInfo(location: locations.locations[i])
                    newDiningLocations.append(diningInfo)
                }
                diningLocations = newDiningLocations
                lastRefreshed = Date()
                isLoading = false
            case .failure(let error):
                print(error)
                loadFailed = true
            }
        }
    }
    
    // Start a perpetually running timer to refresh the open statuses, so that they automatically switch as appropriate without
    // needing to refresh the data. You don't need to yell at the API again to know that the location opening at 11:00 AM should now
    // display "Open" instead of "Opening Soon" now that it's 11:01.
    private func updateOpenStatuses() async {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            for location in diningLocations.indices {
                diningLocations[location].updateOpenStatus()
            }
        }
    }
    
    // The dining locations need to be sorted before being displayed. Favorites should always be shown first, followed by non-favorites.
    // Afterwards, filters the sorted list based on any current search text and the "open locations only" filtering option.
    private var filteredLocations: [DiningLocation] {
        var newLocations = diningLocations
        // Because "The Commons" should be C for "Commons" and not T for "The".
        func removeThe(_ name: String) -> String {
            let lowercased = name.lowercased()
            if lowercased.hasPrefix("the ") {
                return String(name.dropFirst(4))
            }
            return name
        }
        newLocations.sort { firstLoc, secondLoc in
            let firstLocIsFavorite = favorites.contains(firstLoc)
            let secondLocIsFavorite = favorites.contains(secondLoc)
            // Favorites get priority!
            if firstLocIsFavorite != secondLocIsFavorite {
                return firstLocIsFavorite && !secondLocIsFavorite
            }
            // Additional sorting rule that sorts open locations ahead of closed locations, if enabled.
            if openLocationsFirst {
                let firstIsOpen = (firstLoc.open == .open || firstLoc.open == .closingSoon)
                let secondIsOpen = (secondLoc.open == .open || secondLoc.open == .closingSoon)
                if firstIsOpen != secondIsOpen {
                    return firstIsOpen && !secondIsOpen
                }
            }
            return removeThe(firstLoc.name)
                .localizedCaseInsensitiveCompare(removeThe(secondLoc.name)) == .orderedAscending
        }
        // Search/open only filtering step.
        newLocations = newLocations.filter { location in
            let searchedLocations = searchText.isEmpty || location.name.localizedCaseInsensitiveContains(searchText)
            let openLocations = !openLocationsOnly || location.open == .open || location.open == .closingSoon
            return searchedLocations && openLocations
        }
        return newLocations
    }
    
    var body: some View {
        NavigationStack() {
            if isLoading {
                VStack {
                    if loadFailed {
                        Image(systemName: "wifi.exclamationmark.circle")
                            .resizable()
                            .frame(width: 75, height: 75)
                            .foregroundStyle(.accent)
                        Text("An error occurred while fetching dining data. Please check your network connection and try again.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: {
                            loadFailed = false
                            Task {
                                await getDiningData()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .padding(.top, 10)
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
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            } else {
                VStack() {
                    List {
                        Section(content: {
                            NavigationLink(destination: VisitingChefs()) {
                                Text("Today's Visiting Chefs")
                            }
                        })
                        Section(content: {
                            ForEach(filteredLocations, id: \.self) { location in
                                NavigationLink(destination: DetailView(location: location)) {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(location.name)
                                            if favorites.contains(location) {
                                                Image(systemName: "star.fill")
                                                    .foregroundStyle(.yellow)
                                            }
                                        }
                                        switch location.open {
                                        case .open:
                                            Text("Open")
                                                .foregroundStyle(.green)
                                        case .closed:
                                            Text("Closed")
                                                .foregroundStyle(.red)
                                        case .openingSoon:
                                            Text("Opening Soon")
                                                .foregroundStyle(.orange)
                                        case .closingSoon:
                                            Text("Closing Soon")
                                                .foregroundStyle(.orange)
                                        }
                                        if let times = location.diningTimes, !times.isEmpty {
                                            ForEach(times, id: \.self) { time in
                                                Text("\(dateDisplay.string(from: time.openTime)) - \(dateDisplay.string(from: time.closeTime))")
                                                    .foregroundStyle(.secondary)
                                            }
                                        } else {
                                            Text("Not Open Today")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .swipeActions {
                                    Button(action: {
                                        withAnimation {
                                            if favorites.contains(location) {
                                                favorites.remove(location)
                                            } else {
                                                favorites.add(location)
                                            }
                                        }
                                        
                                    }) {
                                        if favorites.contains(location) {
                                            Label("Unfavorite", systemImage: "star")
                                        } else {
                                            Label("Favorite", systemImage: "star")
                                        }
                                    }
                                    .tint(favorites.contains(location) ? .yellow : nil)
                                }
                            }
                        }, footer: {
                            if let lastRefreshed {
                                VStack(alignment: .center) {
                                    Text("Last refreshed: \(lastRefreshed.formatted())")
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        })
                    }
                }
                .navigationTitle("RIT Dining")
                .searchable(text: $searchText, prompt: "Search")
                .refreshable {
                    await getDiningData()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: {
                                Task {
                                    await getDiningData()
                                }
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            Divider()
                            NavigationLink(destination: AboutView()) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.accentColor)
                                Text("About")
                            }
                            Button(action: {
                                showingDonationSheet = true
                            }) {
                                Label("Donate", systemImage: "heart")
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Menu {
                            Toggle(isOn: $openLocationsOnly) {
                                Label("Hide Closed Locations", systemImage: "eye.slash")
                            }
                            Toggle(isOn: $openLocationsFirst) {
                                Label("Open Locations First", systemImage: "arrow.up.arrow.down")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                        if #unavailable(iOS 26.0) {
                            Spacer()
                        }
                    }
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.flexible, placement: .bottomBar)
                        DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    }
                }
            }
        }
        .environment(favorites)
        .task {
            await getDiningData()
            await updateOpenStatuses()
        }
        .sheet(isPresented: $showingDonationSheet) {
            DonationView()
        }
    }
}

#Preview {
    ContentView()
}
