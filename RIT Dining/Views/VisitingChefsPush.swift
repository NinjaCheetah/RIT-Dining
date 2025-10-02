//
//  VisitingChefsPush.swift
//  RIT Dining
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

struct VisitingChefPush: View {
    @AppStorage("visitingChefPushEnabled") var pushEnabled: Bool = false
    @Environment(NotifyingChefs.self) var notifyingChefs
    @State private var pushAllowed: Bool = false
    private let visitingChefs = [
        "California Rollin' Sushi",
        "D'Mangu",
        "Esan's Kitchen",
        "Halal n Out",
        "just chik'n",
        "KO-BQ",
        "Macarollin'",
        "P.H. Express",
        "Tandoor of India"
    ]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Visiting Chef Notifications"),
                    footer: Text(!pushAllowed ? "You must allow notifications from RIT Dining to use this feature." : "")) {
                    Toggle(isOn: $pushEnabled) {
                        Text("Notifications Enabled")
                    }
                    .disabled(!pushAllowed)
                }
                Section(footer: Text("Get notified when a specific visiting chef is on campus and where they'll be.")) {
                    ForEach(visitingChefs, id: \.self) { chef in
                        Toggle(isOn: Binding(
                            get: {
                                notifyingChefs.contains(chef)
                            },
                            set: { isOn in
                                if isOn {
                                    notifyingChefs.add(chef)
                                } else {
                                    notifyingChefs.remove(chef)
                                }
                            }
                        )) {
                            Text(chef)
                        }
                    }
                }
                .disabled(!pushAllowed || !pushEnabled)
            }
            Spacer()
        }
        .onAppear {
            Task {
                let center = UNUserNotificationCenter.current()
                do {
                    try await center.requestAuthorization(options: [.alert])
                } catch {
                    print(error)
                }
                let settings = await center.notificationSettings()
                guard (settings.authorizationStatus == .authorized) else { pushEnabled = false; return }
                pushAllowed = true
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    VisitingChefPush()
}
