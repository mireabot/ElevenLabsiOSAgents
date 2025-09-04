//
//  ElevenLabsiOSAgentsApp.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/6/25.
//

import SwiftUI

@main
struct ElevenLabsiOSAgentsApp: App {
    var body: some Scene {
        WindowGroup {
            FitnessAgentsHomeView()
                .preferredColorScheme(.dark)
        }
    }
}
