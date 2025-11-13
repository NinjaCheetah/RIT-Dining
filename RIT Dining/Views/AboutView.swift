//
//  AboutView.swift
//  RIT Dining
//
//  Created by Campbell on 9/12/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    
    var body: some View {
        VStack(alignment: .leading) {
            Image("Icon")
                .resizable()
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Text("TigerDine")
                .font(.title)
                .fontWeight(.bold)
            Text("An unofficial RIT Dining app")
                .font(.subheadline)
            Text("Version \(appVersionString) (\(buildNumber))")
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            VStack(alignment: .leading, spacing: 10) {
                Text("Dining locations, their descriptions, and their opening hours are sourced from the RIT student-run TigerCenter API. Building occupancy information is sourced from the official RIT maps API. Menu and nutritional information is sourced from the data provided to FD MealPlanner by RIT Dining through the FD MealPlanner API.")
                Text("This app is not affiliated, associated, authorized, endorsed by, or in any way officially connected with the Rochester Institute of Technology. This app is student created and maintained.")
                VStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 8) {
                        Button(action: {
                            openURL(URL(string: "https://github.com/NinjaCheetah/TigerDine")!)
                        }) {
                            Label("Source Code", systemImage: "network")
                        }
                        Button(action: {
                            openURL(URL(string: "https://tigercenter.rit.edu/")!)
                        }) {
                            Label("TigerCenter", systemImage: "fork.knife.circle")
                        }
                    }
                    HStack(spacing: 8) {
                        Button(action: {
                            openURL(URL(string: "https://maps.rit.edu/")!)
                        }) {
                            Label("Official RIT Map", systemImage: "map")
                        }
                        Button(action: {
                            openURL(URL(string: "https://fdmealplanner.com/")!)
                        }) {
                            Label("FD MealPlanner", systemImage: "menucard")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AboutView()
}
