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
        
        let decoded: Result<DiningLocationParser, Error> = Result(catching: { try JSONDecoder().decode(DiningLocationParser.self, from: data) })
        completionHandler(decoded)
    }.resume()
}

// Get the occupancy information for a location using its TigerCenter API location ID.
// This function is very messy but as the comment at the top of the file says, all of this async API access code is rough.
func getOccupancyPercentage(locationId: Int, completionHandler: @escaping (Result<Double, Error>) -> Void) {
    // We need to use the TigerCenter location ID to get the maps API ID.
    var url_string = "https://maps.rit.edu/api/api-dining.php?id=\(locationId)"
    print("making request to \(url_string)")
    
    guard let url = URL(string: url_string) else {
        print("Invalid URL")
        return
    }
    let request = URLRequest(url: url)
    
    var mapsId: Int = 0
    
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
        
        do {
            let decoded = try JSONDecoder().decode(MapsMiddlemanParser.self, from: data)
            mapsId = Int(decoded.properties.mdoid)!
            
            // Use the newly-acquired maps ID to request the occupancy information for the location.
            url_string = "https://maps.rit.edu/proxySearch/densityMapDetail.php?mdo=\(mapsId)"
            print("making request to \(url_string)")
            
            guard let url = URL(string: url_string) else {
                print("Invalid URL")
                return
            }
            let occ_request = URLRequest(url: url)
            
            URLSession.shared.dataTask(with: occ_request) { data, response, error in
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
                
                do {
                    let occupancy = try JSONDecoder().decode([DiningOccupancyParser].self, from: data)
                    if !occupancy.isEmpty {
                        print("current occupancy: \(occupancy[0].count)")
                        print("maximum occupancy: \(occupancy[0].max_occ)")
                        let occupancyPercentage = Double(occupancy[0].count) / Double(occupancy[0].max_occ) * 100
                        print("occupancy percentage: \(occupancyPercentage)%")
                        completionHandler(.success(occupancyPercentage))
                    } else {
                        completionHandler(.failure(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode JSON"))))
                    }
                } catch {
                    completionHandler(.failure(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode JSON"))))
                }
            }.resume()
        } catch {
            completionHandler(.failure(DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode JSON"))))
        }
    }.resume()
}
