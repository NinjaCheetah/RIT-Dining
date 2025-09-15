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
    let date_string: String = date ?? getAPIFriendlyDateString(date: Date())
    let url_string = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-all?date=\(date_string)"
    
    guard let url = URL(string: url_string) else {
        print("Invalid URL")
        return
    }
    let request = URLRequest(url: url)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completionHandler(.failure(error))
            return
        }
        
        guard let data = data else {
            completionHandler(.failure(URLError(.badServerResponse)))
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
    let date_string: String = date ?? getAPIFriendlyDateString(date: Date())
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

func parseOpenStatus(openTime: Date, closeTime: Date) -> OpenStatus {
    // This can probably be done a little cleaner but it's okay for now. If the location is open but the close date is within the next
    // 30 minutes, label it as closing soon, and do the opposite if it's closed but the open date is within the next 30 minutes.
    let calendar = Calendar.current
    let now = Date()
    var openStatus: OpenStatus = .closed
    if now >= openTime && now <= closeTime {
        // This is basically just for Bytes, it checks the case where the open and close times are exactly 24 hours apart, which is
        // only true for 24-hour locations.
        if closeTime == calendar.date(byAdding: .day, value: 1, to: openTime)! {
            openStatus = .open
        } else if closeTime < calendar.date(byAdding: .minute, value: 30, to: now)! {
            openStatus = .closingSoon
        } else {
            openStatus = .open
        }
    } else if openTime <= calendar.date(byAdding: .minute, value: 30, to: now)! && closeTime > now {
        openStatus = .openingSoon
    } else {
        openStatus = .closed
    }
    return openStatus
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
            visitingChefs: nil,
            dailySpecials: nil)
    }
    
    var openStrings: [String] = []
    var closeStrings: [String] = []
    
    // Dining locations have a regular schedule, but then they also have exceptions listed for days like weekends or holidays. If there
    // are exceptions, use those times for the day, otherwise we can just use the default times.
    for event in location.events {
        if let exceptions = event.exceptions, !exceptions.isEmpty {
            // Only save the exception times if the location is actually open during those times.
            if exceptions[0].open {
                openStrings.append(exceptions[0].startTime)
                closeStrings.append(exceptions[0].endTime)
            }
        } else {
            openStrings.append(event.startTime)
            closeStrings.append(event.endTime)
        }
    }
    
    // Early return if there are no valid opening times, most likely because the day's exceptions dictate that the location is closed.
    // Mostly comes into play on holidays.
    if openStrings.isEmpty || closeStrings.isEmpty {
        return DiningLocation(
            id: location.id,
            name: location.name,
            summary: location.summary,
            desc: desc,
            mapsUrl: location.mapsUrl,
            diningTimes: nil,
            open: .closed,
            visitingChefs: nil,
            dailySpecials: nil)
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
        openStatus = parseOpenStatus(openTime: diningTimes[i].openTime, closeTime: diningTimes[i].closeTime)
        // If the first event pass came back closed, loop again in case a later event has a different status. This is mostly to
        // accurately catch Gracie's multiple open periods each day.
        if openStatus != .closed {
            break
        }
    }
    
    // Parse the "menus" array and keep track of visiting chefs at this location, if there are any. If not then we can just save nil.
    // The time formats used for visiting chefs are inconsistent and suck so that part of this code might be kind of rough. I can
    // probably make it a little better but I think most of the blame goes to TigerCenter here.
    // Also save the daily specials. This is more of a footnote because that's just taking a string and saving it as two strings.
    let visitingChefs: [VisitingChef]?
    let dailySpecials: [DailySpecial]?
    if !location.menus.isEmpty {
        var chefs: [VisitingChef] = []
        var specials: [DailySpecial] = []
        for menu in location.menus {
            if menu.category == "Visiting Chef" {
                print("found visiting chef: \(menu.name)")
                var name: String = menu.name
                let splitString = name.split(separator: "(", maxSplits: 1)
                name = String(splitString[0])
                // Time parsing nonsense starts here. Extracts the time from a string like "Chef (4-7p.m.)", splits it at the "-",
                // strips the non-numerical characters from each part, parses it as a number and adds 12 hours as needed, then creates
                // a Date instance for that time on today's date.
                let timeStrings = String(splitString[1]).replacingOccurrences(of: ")", with: "").split(separator: "-", maxSplits: 1)
                print("raw open range: \(timeStrings)")
                let openTime: Date
                let closeTime: Date
                if let openString = timeStrings.first?.trimmingCharacters(in: .whitespaces) {
                    // If the time is NOT in the morning, add 12 hours.
                    let openHour = if openString.contains("a.m") {
                        Int(openString.filter("0123456789".contains))!
                    } else {
                        Int(openString)! + 12
                    }
                    let openTimeComponents = DateComponents(hour: openHour, minute: 0, second: 0)
                    openTime = calendar.date(
                        bySettingHour: openTimeComponents.hour!,
                        minute: openTimeComponents.minute!,
                        second: openTimeComponents.second!,
                        of: now)!
                } else {
                    break
                }
                if let closeString = timeStrings.last?.filter("0123456789".contains) {
                    // I've chosen to assume that no visiting chef will ever close in the morning. This could bad choice but I have
                    // yet to see any evidence of a visiting chef leaving before noon so far.
                    let closeHour = Int(closeString)! + 12
                    let closeTimeComponents = DateComponents(hour: closeHour, minute: 0, second: 0)
                    closeTime = calendar.date(
                        bySettingHour: closeTimeComponents.hour!,
                        minute: closeTimeComponents.minute!,
                        second: closeTimeComponents.second!,
                        of: now)!
                } else {
                    break
                }
                
                // Parse the chef's status, mapping the OpenStatus to a VisitingChefStatus.
                let visitngChefStatus: VisitingChefStatus = switch parseOpenStatus(openTime: openTime, closeTime: closeTime) {
                case .open:
                        .hereNow
                case .closed:
                    if now < openTime {
                        .arrivingLater
                    } else {
                        .gone
                    }
                case .openingSoon:
                        .arrivingSoon
                case .closingSoon:
                        .leavingSoon
                }
                
                chefs.append(VisitingChef(
                    name: name,
                    description: menu.description ?? "No description available", // Some don't have descriptions, apparently.
                    openTime: openTime,
                    closeTime: closeTime,
                    status: visitngChefStatus))
            } else if menu.category == "Daily Specials" {
                print("found daily special: \(menu.name)")
                let splitString = menu.name.split(separator: "(", maxSplits: 1)
                specials.append(DailySpecial(
                    name: String(splitString[0]),
                    type: String(splitString.count > 1 ? String(splitString[1]) : "").replacingOccurrences(of: ")", with: "")))
            }
        }
        visitingChefs = chefs
        dailySpecials = specials
    } else {
        visitingChefs = nil
        dailySpecials = nil
    }
    
    return DiningLocation(
        id: location.id,
        name: location.name,
        summary: location.summary,
        desc: desc,
        mapsUrl: location.mapsUrl,
        diningTimes: diningTimes,
        open: openStatus,
        visitingChefs: visitingChefs,
        dailySpecials: dailySpecials)
}
