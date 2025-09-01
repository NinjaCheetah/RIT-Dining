//
//  ContentView.swift
//  RIT Dining
//
//  Created by Campbell on 8/31/25.
//

import SwiftUI

struct Location: Hashable {
    let name: String
    let todaysHours: String
    let isOpen: openStatus
}

struct ContentView: View {
    @State private var isLoading = true
    @State private var rotationDegrees: Double = 0
    @State private var diningLocations: [Location] = []
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    // Asynchronously fetch the data for all of the locations and parse their data to display it.
    private func getDiningData() {
        var newDiningLocations: [Location] = []
        getDiningLocation { result in
            DispatchQueue.global().async {
                switch result {
                case .success(let locations):
                    for i in 0..<locations.locations.count {
                        let diningInfo = getLocationInfo(location: locations.locations[i])
                        print(diningInfo.name)
                        
                        // I forgot this before and was really confused why all of the times were in UTC.
                        let display = DateFormatter()
                        display.timeZone = TimeZone(identifier: "America/New_York")
                        display.dateStyle = .none
                        display.timeStyle = .short
                        
                        // Parse the open status and times to create the hours string. If either time is missing, assume it has no openings
                        // and use "Not Open Today". If there are times, then set those to be displayed.
                        let todaysHours: String
                        if diningInfo.openTime == .none || diningInfo.closeTime == .none {
                            todaysHours = "Not Open Today"
                        } else {
                            print("Open:", display.string(from: diningInfo.openTime!),
                                  "Close:", display.string(from: diningInfo.closeTime!))
                            
                            todaysHours = "\(display.string(from: diningInfo.openTime!)) - \(display.string(from: diningInfo.closeTime!))"
                        }
                        DispatchQueue.global().sync {
                            newDiningLocations.append(
                                Location(
                                    name: diningInfo.name,
                                    todaysHours: todaysHours,
                                    isOpen: diningInfo.open
                                )
                            )
                        }
                    }
                    DispatchQueue.global().sync {
                        diningLocations = newDiningLocations
                        isLoading = false
                    }
                case .failure(let error): print(error)
                }
            }
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
                Form {
                    ForEach(diningLocations, id: \.self) { location in
                        VStack(alignment: .leading) {
                            Text(location.name)
                            Text(location.todaysHours)
                            switch location.isOpen {
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
                        }
                    }
                }
                .navigationTitle("RIT Dining")
                .refreshable {
                    getDiningData()
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
