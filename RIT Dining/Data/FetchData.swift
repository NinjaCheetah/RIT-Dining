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

// This code has now been mostly rewritten to be pretty and async instead of being horrifying callback based code in a context where
// callback based code made no sense. I love async!
// Get information for all dining locations.
func getAllDiningInfo(date: String?) async -> Result<DiningLocationsParser, Error> {
    // The endpoint requires that you specify a date, so get today's.
    let dateString: String = date ?? getAPIFriendlyDateString(date: Date())
    let urlString = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-all?date=\(dateString)"
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(DiningLocationsParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

// Get information for just one dining location based on its location ID.
func getSingleDiningInfo(date: String?, locId: Int) async -> Result<DiningLocationParser, Error> {
    // The current date and the location ID are required to get information for just one location.
    let dateString: String = date ?? getAPIFriendlyDateString(date: Date())
    let urlString = "https://tigercenter.rit.edu/tigerCenterApi/tc/dining-single?date=\(dateString)&locId=\(locId)"
    print("making request to \(urlString)")

    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }

    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let decoded = try JSONDecoder().decode(DiningLocationParser.self, from: data)
        return .success(decoded)
    } catch {
        return .failure(error)
    }
}

// Get the occupancy information for a location using its MDO ID, whatever that stands for. This ID is provided alongside the other
// main ID in the data returned by the TigerCenter API.
func getOccupancyPercentage(mdoId: Int) async -> Result<Double, Error> {
    let urlString = "https://maps.rit.edu/proxySearch/densityMapDetail.php?mdo=\(mdoId)"
    print("making request to \(urlString)")
    
    guard let url = URL(string: urlString) else {
        return .failure(URLError(.badURL))
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return .failure(InvalidHTTPError.invalid)
        }
        
        let occupancy = try JSONDecoder().decode([DiningOccupancyParser].self, from: data)
        if !occupancy.isEmpty {
            print("current occupancy: \(occupancy[0].count)")
            print("maximum occupancy: \(occupancy[0].max_occ)")
            let occupancyPercentage = Double(occupancy[0].count) / Double(occupancy[0].max_occ) * 100
            print("occupancy percentage: \(occupancyPercentage)%")
            return .success(occupancyPercentage)
        } else {
            return .failure(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode JSON")))
        }
    } catch {
        return .failure(error)
    }
}
