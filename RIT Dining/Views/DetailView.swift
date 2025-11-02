//
//  DetailView.swift
//  RIT Dining
//
//  Created by Campbell on 9/1/25.
//

import SwiftUI
import SafariServices

struct DetailView: View {
    @State var locationId: Int
    @Environment(Favorites.self) var favorites
    @Environment(DiningModel.self) var model
    @Environment(\.openURL) private var openURL
    @State private var showingSafari: Bool = false
    @State private var openString: String = ""
    @State private var occupancyLoading: Bool = true
    @State private var occupancyPercentage: Double = 0.0

    // This gets the location that we're meant to be displaying details about using the provided ID.
    private var location: DiningLocation {
        return model.locationsByDay[0].first { $0.id == locationId }!
    }
    
    // This creates a list of the time strings for the current day and following 6 days to display in the "Upcoming Hours" section.
    // I realized that it makes a lot more sense to do today + 6 rather than just the current calendar week's hours, because who
    // cares what Tuesday's hours were on Saturday, you want to know what Sunday's hours will be.
    private var weeklyHours: [WeeklyHours] {
        var newWeeklyHours: [WeeklyHours] = []
        for day in model.locationsByDay {
            for location in day {
                if location.id == locationId {
                    let weekdayFormatter = DateFormatter()
                    weekdayFormatter.dateFormat = "EEEE"
                    if let times = location.diningTimes, !times.isEmpty {
                        var timeStrings: [String] = []
                        for time in times {
                            timeStrings.append("\(dateDisplay.string(from: time.openTime)) - \(dateDisplay.string(from: time.closeTime))")
                        }
                        newWeeklyHours.append(
                            WeeklyHours(
                                day: weekdayFormatter.string(from: location.date),
                                date: location.date,
                                timeStrings: timeStrings
                            ))
                    } else {
                        newWeeklyHours.append(
                            WeeklyHours(
                                day: weekdayFormatter.string(from: location.date),
                                date: location.date,
                                timeStrings: ["Closed"]
                            ))
                    }
                }
            }
        }
        return newWeeklyHours
    }
    
    // Still a little broken, does not work for refresh. Need to fix.
    private func getOccupancy() async {
        // Only fetch occupancy data if the location is actually open right now. Otherwise, just exit early and hide the spinner.
        if location.open == .open || location.open == .closingSoon {
            occupancyLoading = true
            switch await getOccupancyPercentage(mdoId: location.mdoId) {
            case .success(let occupancy):
                occupancyPercentage = occupancy
                occupancyLoading = false
            case .failure(let error):
                print(error)
                occupancyLoading = false
            }
        } else {
            occupancyLoading = false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        if favorites.contains(location) {
                            favorites.remove(location)
                        } else {
                            favorites.add(location)
                        }
                    }) {
                        if favorites.contains(location) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.title3)
                        } else {
                            Image(systemName: "star")
                                .foregroundStyle(.yellow)
                                .font(.title3)
                        }
                    }
                    // Open OnDemand. Unfortunately the locations use arbitrary IDs, so just open the main OnDemand page.
                    Button(action: {
                        openURL(URL(string: "https://ondemand.rit.edu")!)
                    }) {
                        Image(systemName: "cart")
                            
                            .font(.title3)
                    }
                    .disabled(location.open == .closed || location.open == .openingSoon)
                    Button(action: {
                        showingSafari = true
                    }) {
                        Image(systemName: "map")
                            .font(.title3)
                    }
                }
                Text(location.summary)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .top, spacing: 3) {
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
                    Text("•")
                        .foregroundStyle(.secondary)
                    VStack {
                        if let times = location.diningTimes, !times.isEmpty {
                            Text(openString)
                                .foregroundStyle(.secondary)
                                .onAppear {
                                    openString = ""
                                    for time in times {
                                        openString += "\(dateDisplay.string(from: time.openTime)) - \(dateDisplay.string(from: time.closeTime)), "
                                    }
                                    openString = String(openString.prefix(openString.count - 2))
                                }
                        } else {
                            Text("Not Open Today")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                HStack(spacing: 0) {
                    ForEach(Range(1...5), id: \.self) { index in
                        if occupancyPercentage > (20 * Double(index)) {
                            Image(systemName: "person.fill")
                        } else {
                            Image(systemName: "person")
                        }
                    }
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 18, height: 18)
                        .opacity(occupancyLoading ? 1 : 0)
                        .task {
                            await getOccupancy()
                        }
                }
                .foregroundStyle(Color.accent.opacity(occupancyLoading ? 0.5 : 1.0))
                .font(.title3)
                .padding(.bottom, 12)
                if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Today's Visiting Chefs")
                            .font(.title3)
                            .fontWeight(.semibold)
                        ForEach(visitingChefs, id: \.self) { chef in
                            HStack(alignment: .top) {
                                Text(chef.name)
                                Spacer()
                                VStack(alignment: .trailing) {
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
                                    Text("\(dateDisplay.string(from: chef.openTime)) - \(dateDisplay.string(from: chef.closeTime))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Divider()
                        }
                    }
                    .padding(.bottom, 12)
                }
                if let dailySpecials = location.dailySpecials, !dailySpecials.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Today's Daily Specials")
                            .font(.title3)
                            .fontWeight(.semibold)
                        ForEach(dailySpecials, id: \.self) { special in
                            HStack(alignment: .top) {
                                Text(special.name)
                                Spacer()
                                Text(special.type)
                                    .foregroundStyle(.secondary)
                            }
                            Divider()
                        }
                    }
                    .padding(.bottom, 12)
                }
                VStack(alignment: .leading) {
                    Text("Upcoming Hours")
                        .font(.title3)
                        .fontWeight(.semibold)
                    ForEach(weeklyHours, id: \.self) { day in
                        HStack(alignment: .top) {
                            Text(day.day)
                            Spacer()
                            VStack {
                                ForEach(day.timeStrings, id: \.self) { timeString in
                                    Text(timeString)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Divider()
                    }
                }
                .padding(.bottom, 12)
                // Ideally I'd like this text to be justified to more effectively use the screen space.
                Text(location.desc)
                    .font(.body)
                    .padding(.bottom, 10)
                Text("IMPORTANT: Some locations' descriptions may refer to them as being cashless during certain hours. This is outdated information, as all RIT Dining locations are now cashless 24/7.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSafari) {
            SafariView(url: URL(string: location.mapsUrl)!)
        }
        .refreshable {
            do {
                try await model.getHoursByDay()
            } catch {
                print(error)
            }
            await getOccupancy()
        }
    }
}
