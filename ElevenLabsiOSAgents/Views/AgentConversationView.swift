//
//  AgentConversationView.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/23/25.
//

import SwiftUI
import FluidGradient
import LiveKit

struct AgentConversationView: View {
    @EnvironmentObject var conversationService: ConversationService
    
    @Binding var presentSessionScreen: Bool
    @State private var showStartAnimation: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                FluidGradient(blobs: conversationService.conversationAgent?.blobs ?? [.blue, .purple])
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(alignment: .bottomLeading, content: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conversationService.conversationAgent?.name ?? "Boost")
                                .font(.system(.headline, weight: .medium))
                                .fontWidth(.expanded)
                            Text(conversationService.conversationAgent?.description ?? "Personal training motivator")
                                .font(.system(.subheadline, weight: .regular))
                                .fontWidth(.expanded)
                                .foregroundStyle(.secondary)
                        }
                        .padding([.leading, .bottom], 16)
                    })
                    .ignoresSafeArea(.container, edges: .top)
                    .opacity(showStartAnimation ? 1 : 0)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 10, content: {
                    if conversationService.showToolResultCard,
                       let toolResult = conversationService.toolResults.first {
                        ToolResultCard(toolResult: toolResult, onDismiss: {
                            conversationService.dismissToolResultCard()
                            // Add own logic to save result to database/local storage
                        })
                        .transition(.opacity)
                    }
                    conversationControls()
                        .opacity(showStartAnimation ? 1 : 0)
                })
                .padding(.horizontal, 16)
            }
            .onAppear {
                Task {
                    // Animate the UI in after a short, non-blocking delay
                    try? await Task.sleep(for: .seconds(0.5))
                    withAnimation(.linear) {
                        showStartAnimation = true
                    }
                    // Start the conversation immediately after
                    //await conversationService.startConversation()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await conversationService.endConversation()
                            withAnimation(.smooth) {
                                showStartAnimation.toggle()
                                presentSessionScreen.toggle()
                            }
                        }
                    } label: {
                        Text("End conversation")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                    .opacity(showStartAnimation ? 1 : 0)
                }
            }
        }
    }
    
    @ViewBuilder
    private func conversationControls() -> some View {
        HStack {
            Text(conversationService.agentState == .speaking ? "\(conversationService.conversationAgent?.name ?? "Boost") is speaking" : "\(conversationService.conversationAgent?.name ?? "Boost") is listening to you")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
                .shimmering()
            
            Spacer()
            
            Button {
                Task {
                    await conversationService.toggleMute()
                }
            } label: {
                Image(systemName: conversationService.isMuted ? "microphone.slash.fill" : "microphone.fill")
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }

        }
        .transition(.blurReplace)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(height: 60)
        .background(Color(uiColor: .secondarySystemFill).opacity(0.4))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.ultraThickMaterial, lineWidth: 1)
        }
    }
}

#Preview {
    AgentConversationView(presentSessionScreen: .constant(true))
        .environmentObject(ConversationService())
        .preferredColorScheme(.dark)
}
