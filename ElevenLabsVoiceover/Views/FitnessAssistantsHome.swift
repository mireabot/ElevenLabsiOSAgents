//
//  FitnessAssistantsHome.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 8/20/25.
//

import SwiftUI
import FluidGradient

struct FitnessAssistantsHome: View {
    private let assistants: [Assistant] = [
        Assistants.nutritionCoach.assistant,
        Assistants.sleepExpert.assistant,
        Assistants.fitnessTrainer.assistant,
        Assistants.yogaInstructor.assistant
    ]
    
    private let features: [String: Image] = [
        "Personalized Workouts": Image(systemName: "figure.walk"),
        "Nutrition Guidance": Image(systemName: "fork.knife"),
        "Progress Tracking": Image(systemName: "point.3.filled.connected.trianglepath.dotted"),
        "Mental Wellness": Image(systemName: "brain.head.profile"),
        "Sleep Optimization": Image(systemName: "moon.fill")
    ]
    
    enum AnimationPhase: CaseIterable {
        case start, middle, end
    }
    
    @StateObject private var conversationService = ConversationService()
    
    // Variables controlling animation of agent selection and changing layout
    @State private var assistantIsSelected: Bool = false
    @State private var sessionShouldStart: Bool = false
    var body: some View {
        ZStack {
            if sessionShouldStart {
                AssistantConversationView(presentSessionScreen: $sessionShouldStart)
                    .environmentObject(conversationService)
            } else {
                VStack {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fitness assistant")
                                .font(.system(size: 34, weight: .bold))
                                .fontWidth(.expanded)
                                .foregroundStyle(.primary)
                            Text("powered by ElevenLabs")
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HorizontalTagsLayout(horizontalSpacing: 8) {
                            ForEach(features.keys.sorted(), id: \.self) { key in
                                featureChip(feature: key, image: features[key]!)
                            }
                        }
                    }
                    .padding([.horizontal, .top], 16)
                    
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(assistants, id: \.id) { assistant in
                                AssistantCard(assistant: assistant)
                                    .onTapGesture {
                                        conversationService.selectAgent(assistant)
                                        startSessionAnimation()
                                    }
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal)
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .phaseAnimator(AnimationPhase.allCases, trigger: assistantIsSelected) { content, phase in
                    content
                        .blur(radius: phase == .start ? 0 : 10)
                        .scaleEffect(phase == .middle ? 0.99 : 1)
                        .opacity(phase == .end ? 0 : 1)
                }
            }
        }
    }
    
    @ViewBuilder
    private func featureChip(feature: String, image: Image) -> some View {
        HStack {
            image
                .foregroundColor(.teal)
                .frame(width: 20, height: 20)
            Text(feature)
                .font(.footnote)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(uiColor: .secondarySystemFill).opacity(0.4))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.ultraThickMaterial, lineWidth: 1)
        }
    }
    
    private func startSessionAnimation() {
        var transaction = Transaction(animation: .linear)
        transaction.addAnimationCompletion(criteria: .removed) {
            sessionShouldStart.toggle()
        }
        withTransaction(transaction) {
            assistantIsSelected.toggle()
        }
    }
}

#Preview {
    FitnessAssistantsHome()
}
