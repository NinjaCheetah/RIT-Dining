//
//  DetailView.swift
//  RIT Dining
//
//  Created by Campbell on 9/1/25.
//

import SwiftUI
import SafariServices

// Gross disgusting UIKit code :(
// There isn't a direct way to use integrated Safari from SwiftUI, except maybe in iOS 26? I'm not targeting that though so I must fall
// back on UIKit stuff.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct DetailView: View {
    @State var location: DiningLocation
    @State private var isLoading: Bool = true
    @State private var rotationDegrees: Double = 0
    @State private var showingSafari: Bool = false
    @State private var openString: String = ""
    @State private var week: [Date] = []
    @State private var weeklyHours: [[String]] = []
    private let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    private let display: DateFormatter = {
        let display = DateFormatter()
        display.timeZone = TimeZone(identifier: "America/New_York")
        display.dateStyle = .none
        display.timeStyle = .short
        return display
    }()
    
    private func requestDone(result: Result<DiningLocationParser, Error>) -> Void {
        switch result {
        case .success(let location):
            let diningInfo = parseLocationInfo(location: location)
            if let times = diningInfo.diningTimes, !times.isEmpty {
                var timeStrings: [String] = []
                for time in times {
                    timeStrings.append("\(display.string(from: time.openTime)) - \(display.string(from: time.closeTime))")
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
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
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
                                            openString += "\(display.string(from: time.openTime)) - \(display.string(from: time.closeTime)), "
                                        }
                                        openString = String(openString.prefix(openString.count - 2))
                                    }
                            } else {
                                Text("Not Open Today")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    Button(action: {
                        showingSafari = true
                    }) {
                        Text("View on Map")
                    }
                    .padding(.bottom, 10)
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
                    .padding(.bottom, 10)
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
        visitingChefs: nil))
}
