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
    @State private var notifyingChefs = NotifyingChefs()
    @State private var model = DiningModel()
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @State private var showingDonationSheet: Bool = false
    @State private var rotationDegrees: Double = 0
    @State private var diningLocations: [DiningLocation] = []
    @State private var searchText: String = ""
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    // Small wrapper around the method on the model so that errors can be handled by showing the uh error screen.
    private func getDiningData() async {
        do {
            try await model.getHoursByDay()
            isLoading = false
        } catch {
            isLoading = true
            loadFailed = true
        }
    }
    
    // Start a perpetually running timer to refresh the open statuses, so that they automatically switch as appropriate without
    // needing to refresh the data. You don't need to yell at the API again to know that the location opening at 11:00 AM should now
    // display "Open" instead of "Opening Soon" now that it's 11:01.
    private func updateOpenStatuses() async {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            model.updateOpenStatuses()
            // If the last refreshed date isn't today, that means we probably passed midnight and need to refresh the data.
            // So do that.
            if !Calendar.current.isDateInToday(model.lastRefreshed ?? Date()) {
                Task {
                    await getDiningData()
                }
            }
        }
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
                                Text("Upcoming Visiting Chefs")
                            }
                        })
                        Section(content: {
                            LocationList(
                                diningLocations: $model.locationsByDay[0],
                                openLocationsFirst: $openLocationsFirst,
                                openLocationsOnly: $openLocationsOnly,
                                searchText: $searchText
                            )
                        }, footer: {
                            if let lastRefreshed = model.lastRefreshed {
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
//                            NavigationLink(destination: VisitingChefPush()) {
//                                Image(systemName: "bell.badge")
//                                    .foregroundColor(.accentColor)
//                                Text("Notifications")
//                            }
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
        .environment(notifyingChefs)
        .environment(model)
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
