//
//  FoodTruckView.swift
//  RIT Dining
//
//  Created by Campbell on 10/5/25.
//

import SwiftUI
import SafariServices

struct FoodTruckView: View {
    @State private var foodTruckEvents: [FoodTruckEvent] = []
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    @State private var rotationDegrees: Double = 0
    @State private var showingSafari: Bool = false
    
    private var animation: Animation {
        .linear
        .speed(0.1)
        .repeatForever(autoreverses: false)
    }
    
    private func doFoodTruckStuff() async {
        switch await getFoodTruckPage() {
        case .success(let schedule):
            foodTruckEvents = parseWeekendFoodTrucks(htmlString: schedule)
            isLoading = false
        case .failure(let error):
            print(error)
            loadFailed = true
        }
    }
    
    var body: some View {
        if isLoading {
            VStack {
                if loadFailed {
                    Image(systemName: "wifi.exclamationmark.circle")
                        .resizable()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(.accent)
                    Text("An error occurred while fetching food truck data. Please check your network connection and try again.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Image(systemName: "truck.box")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 75, height: 75)
                        .foregroundStyle(.accent)
                        .rotationEffect(.degrees(rotationDegrees))
                        .onAppear {
                            withAnimation(animation) {
                                rotationDegrees = 360.0
                            }
                        }
                    Text("One moment...")
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                await doFoodTruckStuff()
            }
            .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Weekend Food Trucks")
                            .font(.title)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: {
                            showingSafari = true
                        }) {
                            Image(systemName: "network")
                                .foregroundStyle(.accent)
                                .font(.title3)
                        }
                    }
                    ForEach(foodTruckEvents, id: \.self) { event in
                        Divider()
                        Text(visitingChefDateDisplay.string(from: event.date))
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(dateDisplay.string(from: event.openTime)) - \(dateDisplay.string(from: event.closeTime))")
                            .font(.title3)
                        ForEach(event.trucks, id: \.self) { truck in
                            Text(truck)
                        }
                        Spacer()
                    }
                    Spacer()
                    Text("Food truck data is sourced directly from the RIT Events website, and may not be presented correctly. Use the button in the top right to access the RIT Events website directly to see the original source of the information.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
            }
            .sheet(isPresented: $showingSafari) {
                SafariView(url: URL(string: "https://www.rit.edu/events/weekend-food-trucks")!)
            }
        }
    }
}
