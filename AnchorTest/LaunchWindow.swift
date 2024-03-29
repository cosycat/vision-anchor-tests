//
//  ContentView.swift
//  AnchorTest
//
//  Created by Flavia Brogle on 18.03.2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct LaunchWindow: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle) { phase in
                switch phase {
                    case .empty:
                        Text("Loading...")
                    case .success(let model):
                        model.padding(.bottom, 50)
                    case .failure(let error):
                        Text("Error: \(error.localizedDescription)")
                @unknown default:
                    Text("Unknown")
                }
            }

            Text("Hello, world!")

            Toggle("Show ImmersiveSpace", isOn: $showImmersiveSpace)
                .font(.title)
                .frame(width: 360)
                .padding(24)
                .glassBackgroundEffect()
        }
        .padding()
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    LaunchWindow()
}
