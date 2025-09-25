//
//  VisitingChefs.swift
//  RIT Dining
//
//  Created by Campbell on 9/8/25.
//

import SwiftUI

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct VisitingChefs: View {
    @State private var locationsWithChefs: [DiningLocation] = []
    @State private var isLoading: Bool = true
    @State private var rotationDegrees: Double = 0
    @State private var daySwitcherRotation: Double = 0
    @State private var safariUrl: IdentifiableURL?
    @State private var isTomorrow: Bool = false
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    // Asynchronously fetch the data for all of the locations on the given date (only ever today or tomorrow) to get the visiting chef
    // information.
    private func getDiningDataForDate(date: String) async {
        var newDiningLocations: [DiningLocation] = []
        getAllDiningInfo(date: date) { result in
            switch result {
            case .success(let locations):
                for i in 0..<locations.locations.count {
                    let diningInfo = parseLocationInfo(location: locations.locations[i])
                    print(diningInfo.name)
                    // Only save the locations that actually have visiting chefs to avoid extra iterations later.
                    if let visitingChefs = diningInfo.visitingChefs, !visitingChefs.isEmpty {
                        newDiningLocations.append(diningInfo)
                    }
                }
                locationsWithChefs = newDiningLocations
                isLoading = false
            case .failure(let error): print(error)
            }
        }
    }
    
    private func getDiningData() async {
        isLoading = true
        let dateString: String
        if !isTomorrow {
            dateString = getAPIFriendlyDateString(date: Date())
            print("fetching visiting chefs for date \(dateString) (today)")
        } else {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
            dateString = getAPIFriendlyDateString(date: tomorrow)
            print("fetching visiting chefs for date \(dateString) (tomorrow)")
        }
        await getDiningDataForDate(date: dateString)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    if !isTomorrow {
                        Text("Today's Visiting Chefs")
                            .font(.title)
                            .fontWeight(.bold)
                    } else {
                        Text("Tomorrow's Visiting Chefs")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation(Animation.linear.speed(1.5)) {
                            if isTomorrow {
                                daySwitcherRotation = 0.0
                            } else {
                                daySwitcherRotation = 180.0
                            }
                        }
                        isTomorrow.toggle()
                        Task {
                            await getDiningData()
                        }
                    }) {
                        Image(systemName: "chevron.right.circle")
                            .rotationEffect(.degrees(daySwitcherRotation))
                            .font(.title)
                    }
                }
                if isLoading {
                    VStack {
                        Image(systemName: "fork.knife.circle")
                            .resizable()
                            .frame(width: 75, height: 75)
                            .foregroundStyle(.accent)
                            .rotationEffect(.degrees(rotationDegrees))
                            .onAppear {
                                rotationDegrees = 0.0
                                withAnimation(animation) {
                                    rotationDegrees = 360.0
                                }
                            }
                        Text("Loading...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 25)
                } else {
                    if locationsWithChefs.isEmpty {
                        Text("No visiting chefs today")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(locationsWithChefs, id: \.self) { location in
                        if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                            VStack(alignment: .leading) {
                                Divider()
                                HStack(alignment: .center) {
                                    Text(location.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Button(action: {
                                        safariUrl = IdentifiableURL(url: URL(string: location.mapsUrl)!)
                                    }) {
                                        Image(systemName: "map")
                                            .foregroundStyle(.accent)
                                    }
                                }
                                ForEach(visitingChefs, id: \.self) { chef in
                                    Spacer()
                                    Text(chef.name)
                                        .fontWeight(.semibold)
                                    HStack(spacing: 3) {
                                        if !isTomorrow {
                                            switch chef.status {
                                            case .hereNow:
                                                Text("Here Now")
                                                    .foregroundStyle(.green)
                                            case .gone:
                                                Text("Left For Today")
                                                    .foregroundStyle(.red)
                                            case .arrivingLater:
                                                Text("Arriving Later")
                                                    .foregroundStyle(.red)
                                            case .arrivingSoon:
                                                Text("Arriving Soon")
                                                    .foregroundStyle(.orange)
                                            case .leavingSoon:
                                                Text("Leaving Soon")
                                                    .foregroundStyle(.orange)
                                            }
                                        } else {
                                            Text("Arriving Tomorrow")
                                                .foregroundStyle(.red)
                                        }
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        Text("\(dateDisplay.string(from: chef.openTime)) - \(dateDisplay.string(from: chef.closeTime))")
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(chef.description)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .sheet(item: $safariUrl) { url in
            SafariView(url: url.url)
        }
        .task {
            await getDiningData()
        }
        .refreshable {
            await getDiningData()
        }
    }
}

#Preview {
    VisitingChefs()
}
