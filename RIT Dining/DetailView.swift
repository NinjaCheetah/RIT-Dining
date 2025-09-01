//
//  DetailView.swift
//  RIT Dining
//
//  Created by Campbell on 9/1/25.
//

import SwiftUI
import SafariServices

// Gross disgusting UIKit code :(
// There isn't a direct way to use integrated Safari from SwiftUI, except maybe in iOS 26? I'm not targeting that though so I must fall
// back on UIKit stuff.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct DetailView: View {
    @State var location: Location
    @State private var showingSafari: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(location.name)
                    .font(.title)
                Text(location.summary)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                HStack(alignment: .top) {
                    switch location.isOpen {
                    case .open:
                        Text("Open")
                            .foregroundStyle(.green)
                    case .closed:
                        Text("Closed")
                            .foregroundStyle(.red)
                    case .openingSoon:
                        Text("Opening Soon")
                            .foregroundStyle(.orange)
                    case .closingSoon:
                        Text("Closing Soon")
                            .foregroundStyle(.orange)
                    }
                    VStack {
                        ForEach(location.todaysHours, id: \.self) { hours in
                            Text(hours)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, 10)
                Button(action: {
                    showingSafari = true
                }) {
                    Text("View on Map")
                }
                .padding(.bottom, 10)
                Text(location.desc)
                    .font(.body)
                    .padding(.bottom, 10)
                Text("IMPORTANT: Some locations' descriptions may refer to them as being cashless during certain hours. This is outdated information, as all RIT Dining locations are now cashless 24/7.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSafari) {
            SafariView(url: URL(string: location.mapsUrl)!)
        }
    }
}

#Preview {
    DetailView(location: Location(
        name: "Example",
        summary: "A Place",
        desc: "A long description of the place",
        mapsUrl: "https://example.com",
        todaysHours: ["Now - Later"],
        isOpen: .open))
}
