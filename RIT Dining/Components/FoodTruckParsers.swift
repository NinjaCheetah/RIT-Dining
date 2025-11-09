//
//  FoodTruckParsers.swift
//  RIT Dining
//
//  Created by Campbell on 11/3/25.
//

import Foundation
import SwiftSoup

// This code is actually miserable and might break sometimes. Sorry. Parse the HTML of the RIT food trucks web page and build
// a list of food trucks that are going to be there the next time they're there. This is not a good way to get this data but it's
// unfortunately the best way that I think I could make it happen. Sorry again for both my later self and anyone else who tries to
// work on this code.
func parseWeekendFoodTrucks(htmlString: String) -> [FoodTruckEvent] {
    do {
        let doc = try SwiftSoup.parse(htmlString)
        var events: [FoodTruckEvent] = []
        let now = Date()
        let calendar = Calendar.current
        
        let paragraphs = try doc.select("p:has(strong)")
        
        for p in paragraphs {
            let text = try p.text()
            let parts = text.components(separatedBy: .whitespaces).joined(separator: " ")
            
            let dateRegex = /(?:(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),\s+[A-Za-z]+\s+\d+)/
            let date = parts.firstMatch(of: dateRegex).map { String($0.0) } ?? ""
            if date.isEmpty { continue }
            
            let timeRegex = /(\d{1,2}(:\d{2})?\s*[-–]\s*\d{1,2}(:\d{2})?\s*p\.m\.)/
            let time = parts.firstMatch(of: timeRegex).map { String($0.0) } ?? ""
            
            let locationRegex = /A-Z Lot/
            let location = parts.firstMatch(of: locationRegex).map { String($0.0) } ?? ""
            
            let year = Calendar.current.component(.year, from: Date())
            let fullDateString = "\(date) \(year)"
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d yyyy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateParsed = formatter.date(from: fullDateString) ?? now
            
            let timeStrings = time.split(separator: "-", maxSplits: 1)
            print("raw open range: \(timeStrings)")
            var openTime = Date()
            var closeTime = Date()
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
            }
            if let closeString = timeStrings.last?.filter(":0123456789".contains) {
                // I've chosen to assume that no visiting chef will ever close in the morning. This could bad choice but I have
                // yet to see any evidence of a visiting chef leaving before noon so far.
                let closeStringComponents = closeString.split(separator: ":", maxSplits: 1)
                let closeTimeComponents = DateComponents(
                    hour: Int(closeStringComponents[0])! + 12,
                    minute: closeStringComponents.count > 1 ? Int(closeStringComponents[1]) : 0,
                    second: 0)
                closeTime = calendar.date(
                    bySettingHour: closeTimeComponents.hour!,
                    minute: closeTimeComponents.minute!,
                    second: closeTimeComponents.second!,
                    of: now)!
            }
            
            if let ul = try p.nextElementSibling(), ul.tagName() == "ul" {
                let trucks = try ul.select("li").array().map { try $0.text() }
                
                events.append(FoodTruckEvent(
                    date: dateParsed,
                    openTime: openTime,
                    closeTime: closeTime,
                    location: location,
                    trucks: trucks
                ))
                print(events)
            }
        }
        
        return events
    } catch {
        print(error)
        return []
    }
}
