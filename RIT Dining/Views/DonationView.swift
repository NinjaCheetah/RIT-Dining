//
//  DonationView.swift
//  RIT Dining
//
//  Created by Campbell on 9/17/25.
//

import SwiftUI

struct DonationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) private var openURL
    @State private var symbolDrawn: Bool = true
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 12) {
                HStack {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .symbolEffect(.drawOn, isActive: symbolDrawn)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                    symbolDrawn = false
                                }
                            }
                    } else {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                    }
                    Text("Donate")
                        .fontWeight(.bold)
                }
                .font(.title)
                Text("The RIT Dining app is free and open source software!")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("However, the Apple Developer Program is expensive, and I paid $106.19 pretty much just to distribute this app and nothing else. If you can, I'd appreciate it if you wouldn't mind tossing a coin or two my way to help and make that expense a little less painful.")
                    .multilineTextAlignment(.center)
                Text("No pressure though.")
                    .foregroundStyle(.secondary)
                Button(action: {
                    openURL(URL(string: "https://ko-fi.com/ninjacheetah")!)
                }) {
                    HStack(alignment: .center) {
                        Image("kofiLogo")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Tip Me on Ko-fi")
                                .fontWeight(.bold)
                            Text("Chip in as much or as little as you'd like!")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                    .padding(.all, 6)
                    .background (
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                Button(action: {
                    openURL(URL(string: "https://paypal.me/NinjaCheetahX")!)
                }) {
                    HStack(alignment: .center) {
                        Image("paypalLogo")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading) {
                            Text("Send Me Money Directly")
                                .fontWeight(.bold)
                            Text("I have nothing specific to say here!")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                    .padding(.all, 6)
                    .background (
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                }
            }
        }
        .padding(.horizontal, 10)
    }
}

#Preview {
    DonationView()
}
