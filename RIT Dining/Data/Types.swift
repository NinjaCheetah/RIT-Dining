//
//  Types.swift
//  RIT Dining
//
//  Created by Campbell on 9/2/25.
//

import Foundation

// I'll be honest, I am NOT good at representing other people's JSON in my code. This kinda sucks but it gets the job done and can
// be improved later when I feel like it.
struct DiningLocationParser: Decodable {
    // An individual "event", which is just an open period for the location.
    struct Event: Decodable {
        // Hour exceptions for the given event.
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
    // An individual "menu", which can be either a daily special item or a visitng chef. Description needs to be optional because
    // visiting chefs have descriptions but specials do not.
    struct Menu: Decodable {
        let name: String
        let description: String?
        let category: String
    }
    // Other basic information to read from a location's JSON that we'll need later.
    let id: Int
    let name: String
    let summary: String
    let description: String
    let mapsUrl: String
    let events: [Event]
    let menus: [Menu]
}

// Struct that probably doesn't need to exist but this made parsing the list of location responses easy.
struct DiningLocationsParser: Decodable {
    let locations: [DiningLocationParser]
}

// Enum to represent the four possible states a given location can be in.
enum OpenStatus {
    case open
    case closed
    case openingSoon
    case closingSoon
}

// An individual open period for a location.
struct DiningTimes: Equatable, Hashable {
    var openTime: Date
    var closeTime: Date
}

// Enum to represent the five possible states a visiting chef can be in.
enum VisitingChefStatus {
    case hereNow
    case gone
    case arrivingLater
    case arrivingSoon
    case leavingSoon
}

// A visitng chef present at a location.
struct VisitingChef: Equatable, Hashable {
    let name: String
    let description: String
    var openTime: Date
    var closeTime: Date
    let status: VisitingChefStatus
}

struct DailySpecial: Equatable, Hashable {
    let name: String
    let type: String
}

// The basic information about a dining location needed to display it in the app after parsing is finished.
struct DiningLocation: Identifiable, Hashable {
    let id: Int
    let name: String
    let summary: String
    let desc: String
    let mapsUrl: String
    let diningTimes: [DiningTimes]?
    let open: OpenStatus
    let visitingChefs: [VisitingChef]?
    let dailySpecials: [DailySpecial]?
}
