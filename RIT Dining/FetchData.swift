//
//  FetchData.swift
//  RIT Dining
//
//  Created by Campbell on 8/31/25.
//

import Foundation

// I'll be honest, I am NOT good at representing other people's JSON in my code. This kinda sucks but it gets the job done and can
// be improved later when I feel like it.
struct DiningLocation: Decodable {
    struct Events: Decodable {
        struct HoursException: Decodable {
            let id: Int
            let name: String
            let startTime: String
            let endTime: String
            let startDate: String
            let endDate: String
            let open: Bool
        }
        
        let startTime: String
        let endTime: String
        let exceptions: [HoursException]?
    }
    
    let id: Int
    let name: String
    let events: [Events]
}

struct DiningLocations: Decodable {
    let locations: [DiningLocation]
}

enum InvalidHTTPError: Error {
    case invalid
}

// This code came from another project of mine and was used to fetch the GitHub API for update checking. I just copied it here, but it can
// probably be made simpler for this use case.
func getDiningLocation(completionHandler: @escaping (Result<DiningLocations, Error>) -> Void) {
    // The endpoint requires that you specify a date, so get today's.
    let date_string = Date().formatted(.iso8601
        .year().month().day()
        .dateSeparator(.dash))
    let url_string = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-all?date=\(date_string)"
    
    guard let url = URL(string: url_string) else {
        print("Invalid URL")
        return
    }
    let request = URLRequest(url: url)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard case .none = error else { return }
        
        guard let data = data else {
            print("Data error.")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            completionHandler(.failure(InvalidHTTPError.invalid))
            return
        }
        
        let decoded: Result<DiningLocations, Error> = Result(catching: { try JSONDecoder().decode(DiningLocations.self, from: data) })
        completionHandler(decoded)
    }.resume()
}

enum openStatus {
    case open
    case closed
    case openingSoon
    case closingSoon
}

struct DiningTimes: Equatable {
    let openTime: Date
    let closeTime: Date
}

struct DiningInfo {
    let id: Int
    let name: String
    let diningTimes: [DiningTimes]?
    let open: openStatus
}

func getLocationInfo(location: DiningLocation) -> DiningInfo {
    print("beginning parse for \(location.name)")
    
    // Early return if there are no events, good for things like the food trucks which can very easily have no openings in a week.
    if location.events.isEmpty {
        return DiningInfo(
            id: location.id,
            name: location.name,
            diningTimes: .none,
            open: .closed)
    }
    
    var openStrings: [String] = []
    var closeStrings: [String] = []
    
    // Dining locations have a regular schedule, but then they also have exceptions listed for days like weekends or holidays. If there
    // are exceptions, use those times for the day, otherwise we can just use the default times.
    if let exceptions = location.events[0].exceptions, !exceptions.isEmpty {
        // Early return if the exception for the day specifies that the location is closed. Used for things like holidays.
        if !location.events[0].exceptions![0].open {
            return DiningInfo(
                id: location.id,
                name: location.name,
                diningTimes: .none,
                open: .closed)
        }
        openStrings.append(location.events[0].exceptions![0].startTime)
        closeStrings.append(location.events[0].exceptions![0].endTime)
    } else {
        for event in location.events {
            openStrings.append(event.startTime)
            closeStrings.append(event.endTime)
        }
    }
    
    // I hate all of this date component nonsense.
    var openDates: [Date] = []
    var closeDates: [Date] = []
    
    let calendar = Calendar.current
    let now = Date()
    
    for i in 0..<openStrings.count {
        let openParts = openStrings[i].split(separator: ":").map { Int($0) ?? 0 }
        let openTimeComponents = DateComponents(hour: openParts[0], minute: openParts[1], second: openParts[2])
        
        let closeParts = closeStrings[i].split(separator: ":").map { Int($0) ?? 0 }
        let closeTimeComponents = DateComponents(hour: closeParts[0], minute: closeParts[1], second: closeParts[2])
        
        openDates.append(calendar.date(
            bySettingHour: openTimeComponents.hour!,
            minute: openTimeComponents.minute!,
            second: openTimeComponents.second!,
            of: now)!)
        
        closeDates.append(calendar.date(
            bySettingHour: closeTimeComponents.hour!,
            minute: closeTimeComponents.minute!,
            second: closeTimeComponents.second!,
            of: now)!)
    }
    
    // If the closing time is less than or equal to the opening time, it's probably midnight and means either open until midnight
    // or open 24/7, in the case of Bytes.
    for i in 0..<closeDates.count {
        if closeDates[i] <= openDates[i] {
            closeDates[i] = calendar.date(byAdding: .day, value: 1, to: closeDates[i])!
        }
    }
    
    // This can probably be done in a cleaner way but it's okay for now. If the location is open but the close date is within the next
    // 30 minutes, label it as closing soon, and do the opposite if it's closed but the open date is within the next 30 minutes.
    var openStatus: openStatus = .closed
    for i in 0..<openDates.count {
        let isOpen = (now >= openDates[i] && now <= closeDates[i])
        if isOpen {
            if closeDates[i] < calendar.date(byAdding: .minute, value: 30, to: now)! {
                openStatus = .closingSoon
                break
            } else {
                openStatus = .open
                break
            }
        } else {
            if openDates[i] < calendar.date(byAdding: .minute, value: 30, to: now)! {
                openStatus = .openingSoon
                break
            } else {
                openStatus = .closed
            }
        }
    }
    
    var diningTimes: [DiningTimes] = []
    for i in 0..<openDates.count {
        diningTimes.append(DiningTimes(openTime: openDates[i], closeTime: closeDates[i]))
    }
    
    return DiningInfo(
        id: location.id,
        name: location.name,
        diningTimes: diningTimes,
        open: openStatus)
}
