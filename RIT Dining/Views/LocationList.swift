//
//  LocationList.swift
//  RIT Dining
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

// This view handles the actual location list, because having it inside ContentView was too complex (both visually and for the
// type checker too, apparently).
struct LocationList: View {
    @Binding var diningLocations: [DiningLocation]
    @Binding var openLocationsFirst: Bool
    @Binding var openLocationsOnly: Bool
    @Binding var searchText: String
    @Environment(Favorites.self) var favorites
    
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
        ForEach(filteredLocations, id: \.self) { location in
            NavigationLink(destination: DetailView(locationId: location.id)) {
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
    }
}
