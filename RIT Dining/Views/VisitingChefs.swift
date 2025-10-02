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
    @Environment(DiningModel.self) var model
    @State private var locationsWithChefs: [DiningLocation] = []
    @State private var safariUrl: IdentifiableURL?
    @State private var chefDays: [String] = []
    @State private var focusedIndex: Int = 0
    
    // Builds a list of days that each contain a list of dining locations that have visiting chefs to make displaying them
    // as easy as possible.
    private var locationsWithChefsByDay: [[DiningLocation]] {
        var locationsWithChefsByDay = [[DiningLocation]]()
        for day in model.locationsByDay {
            var locationsWithChefs = [DiningLocation]()
            for location in day {
                if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                    locationsWithChefs.append(location)
                }
            }
            locationsWithChefsByDay.append(locationsWithChefs)
        }
        return locationsWithChefsByDay
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Button(action: {
                        focusedIndex -= 1
                    }) {
                        Image(systemName: "chevron.left.circle")
                            .font(.title)
                    }
                    .disabled(focusedIndex == 0)
                    Spacer()
                    Text("Visiting Chefs for \(visitingChefDateDisplay.string(from: model.daysRepresented[focusedIndex]))")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button(action: {
                        focusedIndex += 1
                    }) {
                        Image(systemName: "chevron.right.circle")
                            .font(.title)
                    }
                    .disabled(focusedIndex == 6)
                }
                if locationsWithChefsByDay[focusedIndex].isEmpty {
                    VStack {
                        Divider()
                        Text("No visiting chefs today")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(locationsWithChefsByDay[focusedIndex], id: \.self) { location in
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
                                    if focusedIndex == 0 {
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
                                        Text("Arriving on \(weekdayFromDate.string(from: model.daysRepresented[focusedIndex]))")
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
            .padding(.horizontal, 8)
        }
        .sheet(item: $safariUrl) { url in
            SafariView(url: url.url)
        }
        .refreshable {
            do {
                try await model.getHoursByDay()
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    VisitingChefs()
}
