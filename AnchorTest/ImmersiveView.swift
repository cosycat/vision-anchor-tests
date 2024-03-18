//
//  ImmersiveView.swift
//  AnchorTest
//
//  Created by Flavia Brogle on 18.03.2024.
//

import Foundation
import ARKit
import RealityKit
import QuartzCore
import SwiftUI
import RealityKitContent

struct ImmersiveView: View {
    
    @State var planeHandler: PlaneHandler? = nil
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(scene)
            }
            let rootPlane = Entity()
            planeHandler = PlaneHandler(rootEntity: rootPlane)
            content.add(rootPlane)
        }
    }
    
}

class PlaneHandler {
    @MainActor var planeAnchors: [UUID: PlaneAnchor] = [:]
    @MainActor var entityMap: [UUID: Entity] = [:]
    
    let session = ARKitSession()
    let planeData = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
    
    let rootEntity: Entity
    
    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
        print("init PlaneHandler")
        Task {
            do {
                try await session.run([planeData])
                
                print("session was run")
                for await update in planeData.anchorUpdates {
                    print("update: \(update.anchor.classification.description)")
                    if update.anchor.classification == .window || update.anchor.classification == .unknown {
                        // Skip planes that are windows.
                        continue
                    }
                    switch update.event {
                    case .added, .updated:
                        await updatePlane(update.anchor)
                    case .removed:
                        await removePlane(update.anchor)
                    }
                    
                }
            } catch {
                print("ARKitSession error:", error)
            }
        }
    }
    
    @MainActor
    func updatePlane(_ anchor: PlaneAnchor) {
        print("UpdatePlane: \(anchor)")
        if planeAnchors[anchor.id] == nil {
            let description = anchor.classification.description
            // Add a new entity to represent this plane.
            let entity = ModelEntity(mesh: .generateText(description))
            entityMap[anchor.id] = entity
            entity.transform.scale *= 0.05
//                entity.scale *= 0.05
            
            let extent = anchor.geometry.extent
//            anchor.
            
            rootEntity.addChild(entity)
            
        }
        
        entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
    }

    @MainActor
    func removePlane(_ anchor: PlaneAnchor) {
        print("RemovePlane: \(anchor)")
        entityMap[anchor.id]?.removeFromParent()
        entityMap.removeValue(forKey: anchor.id)
        planeAnchors.removeValue(forKey: anchor.id)
    }

    
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
