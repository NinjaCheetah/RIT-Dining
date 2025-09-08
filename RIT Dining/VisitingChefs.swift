//
//  VisitingChefs.swift
//  RIT Dining
//
//  Created by Campbell on 9/8/25.
//

import SwiftUI

struct VisitingChefs: View {
    @State var diningLocations: [DiningLocation]
    
    var body: some View {
        VStack {
            ForEach(diningLocations, id: \.self) { location in
                if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                    VStack {
                        Text(location.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        ForEach(visitingChefs, id: \.self) { chef in
                            Text(chef.name)
                                .fontWeight(.semibold)
                            Text(chef.description)
                        }
                    }
                    .padding(.bottom, 15)
                }
            }
        }
        .navigationTitle("Visiting Chefs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    VisitingChefs(
        diningLocations: [DiningLocation(
            id: 0,
            name: "Example",
            summary: "A Place",
            desc: "A long description of the place",
            mapsUrl: "https://example.com",
            diningTimes: [DiningTimes(openTime: Date(), closeTime: Date())],
            open: .open,
            visitingChefs: [VisitngChef(name: "Example Chef (1-2 p.m.)", description: "Serves example food")])])
}
