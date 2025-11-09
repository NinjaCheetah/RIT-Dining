//
//  TCtoFDMPMap.swift
//  RIT Dining
//
//  Created by Campbell on 11/8/25.
//

import Foundation

/// Maps the IDs used by TigerCenter to the locationId and accountId values used by FD MealPlanner. This is used to get menus for locations from their detail views.
let tCtoFDMPMap: [Int: (Int, Int)] = [
    // These are ordered based on the way that they're ordered in the FD MealPlanner search API response.
    30: (1, 1), // Artesano
    31: (2, 2), // Beanz
    23: (7, 7), // Crossroads
    25: (8, 8), // Cantina
    34: (6, 6), // Ctr-Alt-DELi
    21: (10, 10), // Gracie's
    22: (4, 4), // Brick City Cafe
    441: (11, 11), // Loaded Latke
    38: (12, 12), // Midnight Oil
    26: (14, 4), // RITZ
    9041: (18, 17), // The College Grind
    24: (15, 14), // The Commons
]
