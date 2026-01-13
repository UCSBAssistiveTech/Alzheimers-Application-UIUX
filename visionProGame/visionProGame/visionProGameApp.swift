//
//  visionProGameApp.swift
//  visionProGame
//
//  Created by Srihari Prazid on 4/13/25.
//

import SwiftUI
import RealityKit

@main
struct visionProGameApp: App {
    var body: some SwiftUI.Scene {
        WindowGroup {
            ReactionGameView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.5, height: 1.0, depth: 1.5, in: .meters)
    }
}
