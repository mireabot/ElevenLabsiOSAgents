//
//  Assistant.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/20/25.
//

import SwiftUI

/// A model representing an AI agent with its configuration and visual properties.
///
/// An agent is defined by its unique identifier registered in the ElevenLabs dashboard,
/// along with visual elements and descriptive information for UI presentation.
/// Learn more https://elevenlabs.io/docs/agents-platform/quickstart
struct Agent: Equatable, Identifiable {
    let id = UUID().uuidString
    let name: String
    let icon: String
    let blobs: [Color]
    let highlights: [Color]
    let model_id: String
    let description: String
    
    /// Creates a new assistant with the specified properties.
    /// - Parameters:
    ///   - name: Display name for the assistant.
    ///   - icon: SF Symbol name for the icon.
    ///   - blobs: Background colors for visual representation.
    ///   - highlights: Highlight colors for visual elements.
    ///   - model_id: Public ID registered in ElevenLabs dashboard. Defaults to "none".
    ///   - description: Brief description of the assistant. Defaults to empty string.
    init(name: String, icon: String, blobs: [Color], highlights: [Color], model_id: String = "none", description: String = "") {
        self.name = name
        self.icon = icon
        self.blobs = blobs
        self.highlights = highlights
        self.model_id = model_id
        self.description = description
    }
    
    static func == (lhs: Agent, rhs: Agent) -> Bool {
        lhs.name == rhs.name && lhs.model_id == rhs.model_id
    }
}

enum Agents: CaseIterable {
    case nutritionCoach
    case fitnessTrainer
    case sleepExpert
    case yogaInstructor
    
    var agent: Agent {
        switch self {
        case .nutritionCoach:
            return Agent(
                name: "Fuel",
                icon: "carrot",
                blobs: [.green, .green, .white, .green.opacity(0.4), .green.opacity(0.8)],
                highlights: [.yellow, .orange, .green, .mint],
                model_id: "agent_9001k3cws170e8yb98wkrhjt7jz3",
                description: "Nutritionl logging agent"
            )
        case .fitnessTrainer:
            return Agent(
                name: "Boost",
                icon: "figure.run",
                blobs: [.red, .red, .white, .red.opacity(0.4), .red.opacity(0.8)],
                highlights: [.orange, .yellow, .red, .pink],
                model_id: "agent-id",
                description: "Personal training motivator"
            )
        case .sleepExpert:
            return Agent(
                name: "Drift",
                icon: "figure.mind.and.body",
                blobs: [.orange, .orange, .orange, .white, .orange.opacity(0.4), .orange.opacity(0.8)],
                highlights: [.mint, .cyan, .orange, .teal],
                model_id: "agent_9201k3cvw4k2f32r978atnm6ybww",
                description: "Sleep companion"
            )
        case .yogaInstructor:
            return Agent(
                name: "Flow",
                icon: "figure.yoga",
                blobs: [.purple, .purple, .white, .purple.opacity(0.4), .purple.opacity(0.8)],
                highlights: [.pink, .red, .purple, .indigo],
                model_id: "agent-id",
                description: "Mindful movement guide"
            )
        }
    }
}
