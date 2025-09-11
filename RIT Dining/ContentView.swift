//
//  ContentView.swift
//  RIT Dining
//
//  Created by Campbell on 8/31/25.
//

import SwiftUI

struct LocationList: View {
    let diningLocations: [DiningLocation]
    
    // I forgot this before and was really confused why all of the times were in UTC.
    private let display: DateFormatter = {
        let display = DateFormatter()
        display.timeZone = TimeZone(identifier: "America/New_York")
        display.dateStyle = .none
        display.timeStyle = .short
        return display
    }()
    
    var body: some View {
        ForEach(diningLocations, id: \.self) { location in
            NavigationLink(destination: DetailView(location: location)) {
                VStack(alignment: .leading) {
                    Text(location.name)
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
                            Text("\(display.string(from: time.openTime)) - \(display.string(from: time.closeTime))")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not Open Today")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var isLoading = true
    @State private var rotationDegrees: Double = 0
    @State private var diningLocations: [DiningLocation] = []
    @State private var lastRefreshed: Date?
    @State private var searchText: String = ""
    @State private var openLocationsOnly: Bool = false
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    // Asynchronously fetch the data for all of the locations and parse their data to display it.
    private func getDiningData() {
        var newDiningLocations: [DiningLocation] = []
        getAllDiningInfo(date: nil) { result in
            DispatchQueue.global().async {
                switch result {
                case .success(let locations):
                    for i in 0..<locations.locations.count {
                        let diningInfo = parseLocationInfo(location: locations.locations[i])
                        print(diningInfo.name)
                        DispatchQueue.global().sync {
                            newDiningLocations.append(diningInfo)
                        }
                    }
                    DispatchQueue.global().sync {
                        diningLocations = newDiningLocations.sorted { $0.name < $1.name }
                        lastRefreshed = Date()
                        isLoading = false
                    }
                case .failure(let error): print(error)
                }
            }
        }
    }
    
    // Allow for searching the list and hiding closed locations. Gets a list of locations that match the search and a list that match
    // the open only filter (.open and .closingSoon) and then returns the ones that match both lists.
    private var filteredLocations: [DiningLocation] {
        diningLocations.filter { location in
            let searchedLocations = searchText.isEmpty || location.name.localizedCaseInsensitiveContains(searchText)
            let openLocations = !openLocationsOnly || location.open == .open || location.open == .closingSoon
            return searchedLocations && openLocations
        }
    }
    
    var body: some View {
        NavigationStack() {
            if isLoading {
                VStack {
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
                .padding()
            } else {
                VStack() {
                    List {
                        if searchText.isEmpty {
                            Section(content: {
                                NavigationLink(destination: VisitingChefs()) {
                                    Text("Today's Visiting Chefs")
                                }
                            })
                        }
                        Section(content: {
                            LocationList(diningLocations: filteredLocations)
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
                .searchable(text: $searchText, prompt: "Search...")
                .refreshable {
                    getDiningData()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: {
                                getDiningData()
                            }) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            Toggle(isOn: $openLocationsOnly) {
                                Label("Hide Closed Locations", systemImage: "eye.slash")
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
            }
        }
        .onAppear {
            getDiningData()
        }
    }
}

#Preview {
    ContentView()
}
