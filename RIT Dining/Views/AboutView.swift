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
            Text("An unofficial RIT Dining app")
                .font(.subheadline)
            Text("Version \(appVersionString) (\(buildNumber))")
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)
            VStack(alignment: .leading, spacing: 10) {
                Text("Dining locations, their descriptions, and their opening hours are sourced from the RIT student-run TigerCenter API. Building occupancy information is sourced from the official RIT maps API.")
                Text("This app is not affiliated, associated, authorized, endorsed by, or in any way officially connected with the Rochester Institute of Technology. This app is student created and maintained.")
                HStack {
                    Button(action: {
                        openURL(URL(string: "https://github.com/NinjaCheetah/TigerDine")!)
                    }) {
                        Text("Source Code")
                    }
                    Text("•")
                        .foregroundStyle(.secondary)
                    Button(action: {
                        openURL(URL(string: "https://tigercenter.rit.edu/")!)
                    }) {
                        Text("TigerCenter")
                    }
                    Text("•")
                        .foregroundStyle(.secondary)
                    Button(action: {
                        openURL(URL(string: "https://maps.rit.edu/")!)
                    }) {
                        Text("Official RIT Map")
                    }
                }
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
