//
//  Assistants.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 8/11/25.
//

import SwiftUI
import FluidGradient

struct AssistantCard: View {
    let assistant: Assistant
    
    init(assistant: Assistant) {
        self.assistant = assistant
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4, content: {
                Text(assistant.name)
                    .font(.system(.title3, weight: .semibold))
                    .fontWidth(.expanded)
                
                Text(assistant.description)
                    .font(.system(.subheadline, weight: .regular))
                    .fontWidth(.expanded)
                    .lineLimit(3)
            })
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            Spacer()
            
            Image(systemName: assistant.icon)
                .font(.system(.title, weight: .medium))
        }
        .padding(.vertical, 16)
        .frame(width: 160, height: 200)
        .background {
            FluidGradient(blobs: assistant.blobs,
                          highlights: assistant.highlights,
                          speed: 0.35,
                          blur: 0.55)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.ultraThickMaterial, lineWidth: 1)
        }
    }
}

#Preview {
    AssistantCard(
        assistant: Assistants.fitnessTrainer.assistant
    )
}
