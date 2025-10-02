//
//  Model.swift
//  RIT Dining
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

@Observable
class DiningModel {
    var locationsByDay = [[DiningLocation]]()
    var daysRepresented = [Date]()
    var lastRefreshed: Date?
    
    // This is the actual method responsible for making requests to the API for the current day and next 6 days to collect all
    // of the information that the app needs for the various view. Making it part of the model allows it to be updated from
    // any view at any time, and prevents excess API requests (if you never refresh, the app will never need to make more than 7
    // calls per launch).
    func getHoursByDay() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let week: [Date] = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
        daysRepresented = week
        var newLocationsByDay = [[DiningLocation]]()
        for day in week {
            let dateString = day.formatted(.iso8601
                .year().month().day()
                .dateSeparator(.dash))
            switch await getAllDiningInfo(date: dateString) {
            case .success(let locations):
                var newDiningLocations = [DiningLocation]()
                for i in 0..<locations.locations.count {
                    let diningInfo = parseLocationInfo(location: locations.locations[i], forDate: day)
                    newDiningLocations.append(diningInfo)
                }
                newLocationsByDay.append(newDiningLocations)
            case .failure(let error):
                throw(error)
            }
        }
        locationsByDay = newLocationsByDay
        lastRefreshed = Date()
    }
    
    // Iterates through all of the locations and updates their open status indicator based on the current time. Does a replace
    // to make sure that it updates any views observing this model.
    func updateOpenStatuses() {
        locationsByDay = locationsByDay.map { day in
            day.map { location in
                var location = location
                location.updateOpenStatus()
                return location
            }
        }
    }
}
