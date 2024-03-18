//
//  AnchorTestApp.swift
//  AnchorTest
//
//  Created by Flavia Brogle on 18.03.2024.
//

import SwiftUI

@main
struct AnchorTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
