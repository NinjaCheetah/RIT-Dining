//
//  AboutView.swift
//  RIT Dining
//
//  Created by Campbell on 9/12/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Image("Icon")
                .resizable()
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            Text("RIT Dining App")
                .font(.title)
            Text("because the RIT dining website is slow!")
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AboutView()
}
