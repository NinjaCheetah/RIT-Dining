//
//  DetailView.swift
//  RIT Dining
//
//  Created by Campbell on 9/1/25.
//

import SwiftUI
import SafariServices

struct DetailView: View {
    @State var location: DiningLocation
    @Environment(Favorites.self) var favorites
    @State private var isLoading: Bool = true
    @State private var rotationDegrees: Double = 0
    @State private var showingSafari: Bool = false
    @State private var openString: String = ""
    @State private var week: [Date] = []
    @State private var weeklyHours: [[String]] = []
    @State private var occupancyLoading: Bool = true
    @State private var occupancyPercentage: Double = 0.0
    private let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    private func requestDone(result: Result<DiningLocationParser, Error>) -> Void {
        switch result {
        case .success(let location):
            let diningInfo = parseLocationInfo(location: location)
            if let times = diningInfo.diningTimes, !times.isEmpty {
                var timeStrings: [String] = []
                for time in times {
                    timeStrings.append("\(dateDisplay.string(from: time.openTime)) - \(dateDisplay.string(from: time.closeTime))")
                }
                weeklyHours.append(timeStrings)
            } else {
                weeklyHours.append(["Closed"])
            }
        case .failure(let error):
            print(error)
        }
        if week.count > 0 {
            DispatchQueue.global().async {
                let date_string = week.removeFirst().formatted(.iso8601
                    .year().month().day()
                    .dateSeparator(.dash))
                getSingleDiningInfo(date: date_string, locationId: location.id, completionHandler: requestDone)
            }
        } else {
            isLoading = false
            print(weeklyHours)
        }
    }
    
    private func getWeeklyHours() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        week = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
            .compactMap { calendar.date(byAdding: .day, value: $0 - dayOfWeek, to: today) }
        DispatchQueue.global().async {
            let date_string = week.removeFirst().formatted(.iso8601
                .year().month().day()
                .dateSeparator(.dash))
            getSingleDiningInfo(date: date_string, locationId: location.id, completionHandler: requestDone)
        }
    }
    
    private func getOccupancy() {
        // Only fetch occupancy data if the location is actually open right now. Otherwise, just exit early and hide the spinner.
        if location.open == .open || location.open == .closingSoon {
            DispatchQueue.main.async {
                getOccupancyPercentage(locationId: location.id) { result in
                    switch result {
                    case .success(let occupancy):
                        DispatchQueue.main.sync {
                            occupancyPercentage = occupancy
                            occupancyLoading = false
                        }
                    case .failure(let error):
                        print(error)
                        DispatchQueue.main.sync {
                            occupancyLoading = false
                        }
                    }
                }
            }
        } else {
            occupancyLoading = false
        }
    }
    
    var body: some View {
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
            .onAppear {
                getWeeklyHours()
            }
            .padding()
        } else {
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
                        Button(action: {
                            showingSafari = true
                        }) {
                            Image(systemName: "map")
                                .foregroundStyle(.accent)
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
                            .onAppear {
                                getOccupancy()
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
                        Text("This Week's Hours")
                            .font(.title3)
                            .fontWeight(.semibold)
                        ForEach(weeklyHours.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(daysOfWeek[index])")
                                Spacer()
                                VStack {
                                    ForEach(weeklyHours[index].indices, id: \.self) { innerIndex in
                                        Text(weeklyHours[index][innerIndex])
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
        }
    }
}

#Preview {
    DetailView(location: DiningLocation(
        id: 0,
        name: "Example",
        summary: "A Place",
        desc: "A long description of the place",
        mapsUrl: "https://example.com",
        diningTimes: [DiningTimes(openTime: Date(), closeTime: Date())],
        open: .open,
        visitingChefs: nil,
        dailySpecials: nil))
}
