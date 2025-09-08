//
//  FetchData.swift
//  RIT Dining
//
//  Created by Campbell on 8/31/25.
//

import Foundation

enum InvalidHTTPError: Error {
    case invalid
}

// This API requesting code came from another project of mine and was used to fetch the GitHub API for update checking. I just copied it
// here, but it can probably be made simpler for this use case.

// Get information for all dining locations.
func getAllDiningInfo(date: String?, completionHandler: @escaping (Result<DiningLocationsParser, Error>) -> Void) {
    // The endpoint requires that you specify a date, so get today's.
    let date_string: String = if let date { date } else {
        Date().formatted(.iso8601
            .year().month().day()
            .dateSeparator(.dash))
    }
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
        
        let decoded: Result<DiningLocationsParser, Error> = Result(catching: { try JSONDecoder().decode(DiningLocationsParser.self, from: data) })
        completionHandler(decoded)
    }.resume()
}

// Get information for just one dining location based on its location ID.
func getSingleDiningInfo(date: String?, locationId: Int, completionHandler: @escaping (Result<DiningLocationParser, Error>) -> Void) {
    // The current date and the location ID are required to get information for just one location.
    let date_string: String = if let date { date } else {
        Date().formatted(.iso8601
            .year().month().day()
            .dateSeparator(.dash))
    }
    let url_string = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-single?date=\(date_string)&locId=\(locationId)"
    print("making request to \(url_string)")
    
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
        
        let decoded: Result<DiningLocationParser, Error> = Result(catching: { try JSONDecoder().decode(DiningLocationParser.self, from: data) })
        completionHandler(decoded)
    }.resume()
}

func parseLocationInfo(location: DiningLocationParser) -> DiningLocation {
    print("beginning parse for \(location.name)")
    
    // The descriptions sometimes have HTML <br /> tags despite also having \n. Those need to be removed.
    let desc = location.description.replacingOccurrences(of: "<br />", with: "")
    
    // Early return if there are no events, good for things like the food trucks which can very easily have no openings in a week.
    if location.events.isEmpty {
        return DiningLocation(
            id: location.id,
            name: location.name,
            summary: location.summary,
            desc: desc,
            mapsUrl: location.mapsUrl,
            diningTimes: nil,
            open: .closed,
            visitingChefs: nil)
    }
    
    var openStrings: [String] = []
    var closeStrings: [String] = []
    
    // Dining locations have a regular schedule, but then they also have exceptions listed for days like weekends or holidays. If there
    // are exceptions, use those times for the day, otherwise we can just use the default times.
    for event in location.events {
        if let exceptions = event.exceptions, !exceptions.isEmpty {
            // Early return if the exception for the day specifies that the location is closed. Used for things like holidays.
            if !exceptions[0].open {
                return DiningLocation(
                    id: location.id,
                    name: location.name,
                    summary: location.summary,
                    desc: desc,
                    mapsUrl: location.mapsUrl,
                    diningTimes: nil,
                    open: .closed,
                    visitingChefs: nil)
            }
            openStrings.append(exceptions[0].startTime)
            closeStrings.append(exceptions[0].endTime)
        } else {
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
    var diningTimes: [DiningTimes] = []
    for i in 0..<openDates.count {
        diningTimes.append(DiningTimes(openTime: openDates[i], closeTime: closeDates[i]))
    }
    
    // If the closing time is less than or equal to the opening time, it's probably midnight and means either open until midnight
    // or open 24/7, in the case of Bytes.
    for i in diningTimes.indices {
        if diningTimes[i].closeTime <= diningTimes[i].openTime {
            diningTimes[i].closeTime = calendar.date(byAdding: .day, value: 1, to: diningTimes[i].closeTime)!
        }
    }
    
    // Sometimes the openings are not in order, for some reason. I'm observing this with Brick City, where for some reason the early opening
    // is event 1, and the later opening is event 0. This is silly so let's reverse it.
    diningTimes.sort { $0.openTime < $1.openTime }
    
    // This can probably be done a little cleaner but it's okay for now. If the location is open but the close date is within the next
    // 30 minutes, label it as closing soon, and do the opposite if it's closed but the open date is within the next 30 minutes.
    var openStatus: OpenStatus = .closed
    for i in diningTimes.indices {
        if now >= diningTimes[i].openTime && now <= diningTimes[i].closeTime {
            if diningTimes[i].closeTime < calendar.date(byAdding: .minute, value: 30, to: now)! {
                openStatus = .closingSoon
            } else {
                openStatus = .open
            }
        } else if diningTimes[i].openTime <= calendar.date(byAdding: .minute, value: 30, to: now)! && diningTimes[i].closeTime > now {
            openStatus = .openingSoon
        } else {
            openStatus = .closed
        }
        // If the first event pass came back closed, loop again in case a later event has a different status. This is mostly to
        // accurately catch Gracie's multiple open periods each day.
        if openStatus != .closed {
            break
        }
    }
    
    // Parse the "menus" array and keep track of visiting chefs at this location, if there are any. If not then we can just save nil.
    // Eventually this will parse out the times, but that's complicated because that data is formatted poorly and inconsistently and
    // I'm not interested in messing with that quite yet.
    let visitingChefs: [VisitngChef]?
    if !location.menus.isEmpty {
        var chefs: [VisitngChef] = []
        for menu in location.menus {
            if menu.category == "Visiting Chef" {
                print("found visiting chef: \(menu.name)")
                chefs.append(VisitngChef(name: menu.name, description: menu.description!))
            }
        }
        visitingChefs = chefs
    } else {
        visitingChefs = nil
    }
    
    return DiningLocation(
        id: location.id,
        name: location.name,
        summary: location.summary,
        desc: desc,
        mapsUrl: location.mapsUrl,
        diningTimes: diningTimes,
        open: openStatus,
        visitingChefs: visitingChefs)
}
