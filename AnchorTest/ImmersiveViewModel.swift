//
//  ImmersiveViewModel.swift
//  AnchorTest
//
//  Created by Flavia Brogle on 23.03.2024.
//

import Foundation
import ARKit
import RealityKit
import QuartzCore
import SwiftUI
import RealityKitContent

@MainActor class ImmersiveViewModel: ObservableObject {
    private let session = ARKitSession()
    private let handTracking = HandTrackingProvider()
    private let sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
    private let planeData = PlaneDetectionProvider(alignments: [.horizontal, .vertical])

    private var contentEntity = Entity()

    private var meshEntities = [UUID: ModelEntity]()
    
    @MainActor var planeAnchors: [UUID: PlaneAnchor] = [:]
    @MainActor var entityMap: [UUID: Entity] = [:]

//    private let fingerEntities: [HandAnchor.Chirality: ModelEntity] = [
//        .left: .createFingertip(),
//        .right: .createFingertip()
//    ]
    
    func processPlaneData(rootEntity: Entity) async {
        //        do {
        //            try await session.run([planeData])
        //        } catch {
        //            print("ARKitSession error:", error)
        //            return
        //        }
        guard await askForPermission(planeData) else { // TODO: test if this also works
            return
        }
        
        for await update in planeData.anchorUpdates {
            print("update: \(update.anchor.classification.description)")
            if update.anchor.classification == .window || update.anchor.classification == .unknown {
                // Skip planes that are windows.
                continue
            }
            switch update.event {
            case .added, .updated:
                updatePlane(update.anchor, rootEntity: rootEntity)
            case .removed:
                removePlane(update.anchor)
            }
        }
        
    }
    
    func processReconstructionUpdates() async {
        do {
            try await session.run([sceneReconstruction])
        } catch {
            print("ARKitSession error:", error)
            return
        }
        
        print("processReconstructionUpdates state: \(sceneReconstruction.state)")
        for await update in sceneReconstruction.anchorUpdates {
            print("anchorUpdates")
            let meshAnchor = update.anchor
            print("\(meshAnchor)")
            
            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
            
            switch update.event {
            case .added:
                let entity = ModelEntity()
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                entity.physicsBody = PhysicsBodyComponent()
                entity.components.set(InputTargetComponent())

                meshEntities[meshAnchor.id] = entity
                contentEntity.addChild(entity)
                print("Added \(meshAnchor)")
            case .updated:
                guard let entity = meshEntities[meshAnchor.id] else { fatalError("...") }
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision?.shapes = [shape]
                print("Updated \(meshAnchor)")
            case .removed:
                meshEntities[meshAnchor.id]?.removeFromParent()
                meshEntities.removeValue(forKey: meshAnchor.id)
                print("Removed \(meshAnchor)")
            }
        }
    }
    
    @MainActor
    func updatePlane(_ anchor: PlaneAnchor, rootEntity: Entity) {
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
    
    private func askForPermission(_ dataProvider: DataProvider) async -> Bool {
        do {
            try await session.run([dataProvider])
        } catch {
            print("ARKitSession error:", error)
            return false
        }
        return true
    }

}
