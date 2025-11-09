//
//  SharedComponents.swift
//  RIT Dining
//
//  Created by Campbell on 9/8/25.
//

import Foundation
import SafariServices
import SwiftUI

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

func getTCAPIFriendlyDateString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func getFDMPAPIFriendlyDateString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}

// The common date formatter that I'm using everywhere that open periods are shown within the app.
let dateDisplay: DateFormatter = {
    let display = DateFormatter()
    display.timeZone = TimeZone(identifier: "America/New_York")
    display.dateStyle = .none
    display.timeStyle = .short
    return display
}()

let visitingChefDateDisplay: DateFormatter = {
    let display = DateFormatter()
    display.dateFormat = "EEEE, MMM d"
    display.locale = Locale(identifier: "en_US_POSIX")
    return display
}()

let weekdayFromDate: DateFormatter = {
    let weekdayFormatter = DateFormatter()
    weekdayFormatter.dateFormat = "EEEE"
    return weekdayFormatter
}()

// Custom view extension that just applies modifiers in a block to the object it's applied to. Mostly useful for splitting up conditional
// modifiers that should only be applied for certain OS versions. (A returning feature from RNGTool!)
extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
