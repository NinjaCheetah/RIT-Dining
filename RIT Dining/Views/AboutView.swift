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
        VStack {
            Image("Icon")
                .resizable()
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Text("RIT Dining App")
                .font(.title)
            Text("because the RIT dining website is slow!")
            Text("Version \(appVersionString) (\(buildNumber))")
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: {
                openURL(URL(string: "https://github.com/NinjaCheetah/RIT-Dining")!)
            }) {
                Label("GitHub Repository", systemImage: "globe")
            }
            Button(action: {
                openURL(URL(string: "https://tigercenter.rit.edu/")!)
            }) {
                Label("TigerCenter API", systemImage: "globe")
            }
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AboutView()
}
