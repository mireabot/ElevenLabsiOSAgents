//
//  ContentView.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 8/6/25.
//

import SwiftUI
import SwiftUI
import ElevenLabs
import Combine
import LiveKit

struct ConversationView: View {
    @StateObject private var viewModel = ConversationViewModel()

    var body: some View {
        ZStack {
            Coordinator(blobCount: 4, tightness: 0.2, sharpness: 3.4, warp1: 1.2, warp2: 3.45, warp3: 4.66, colors: [.blue, .green, .red, .purple])
            VStack(spacing: 20) {
                // Connection status
                Text(viewModel.connectionStatus)
                    .font(.headline)
                    .foregroundColor(viewModel.isConnected ? .green : .red)

                // Chat messages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            MessageBubble(message: message)
                        }
                    }
                }
                .frame(maxHeight: 400)

                // Controls
                HStack(spacing: 16) {
                    Button(viewModel.isConnected ? "End" : "Start") {
                        Task {
                            if viewModel.isConnected {
                                await viewModel.endConversation()
                            } else {
                                await viewModel.startConversation()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button(viewModel.isMuted ? "Unmute" : "Mute") {
                        Task { await viewModel.toggleMute() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.isConnected)

                    Button("Send Message") {
                        Task { await viewModel.sendTestMessage() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.isConnected)
                }

                // Agent state indicator
                if viewModel.isConnected {
                    HStack {
                        Circle()
                            .fill(viewModel.agentState == .speaking ? .blue : .gray)
                            .frame(width: 10, height: 10)
                        Text(viewModel.agentState == .speaking ? "Agent speaking" : "Agent listening")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer() }

            VStack(alignment: .leading) {
                Text(message.role == .user ? "You" : "Agent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(message.content)
                    .padding()
                    .background(message.role == .user ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(12)
            }

            if message.role == .agent { Spacer() }
        }
    }
}

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isConnected = false
    @Published var isMuted = false
    @Published var agentState: AgentState = .listening
    @Published var connectionStatus = "Disconnected"

    private var conversation: Conversation?
    private var cancellables = Set<AnyCancellable>()

    func startConversation() async {
        do {
            conversation = try await ElevenLabs.startConversation(
                agentId: "agent_1001k26adt5yfz6tr30s10h1207v",
                config: ConversationConfig()
            )
            setupObservers()
        } catch {
            print("Failed to start conversation: \(error)")
            connectionStatus = "Failed to connect"
        }
    }

    func endConversation() async {
        await conversation?.endConversation()
        conversation = nil
        cancellables.removeAll()
    }

    func toggleMute() async {
        try? await conversation?.toggleMute()
    }

    func sendTestMessage() async {
        try? await conversation?.sendMessage("Hello from the app!")
    }

    private func setupObservers() {
        guard let conversation else { return }

        conversation.$messages
            .assign(to: &$messages)

        conversation.$state
            .map { state in
                switch state {
                case .idle: return "Disconnected"
                case .connecting: return "Connecting..."
                case .active: return "Connected"
                case .ended: return "Ended"
                case .error: return "Error"
                }
            }
            .assign(to: &$connectionStatus)

        conversation.$state
            .map { $0.isActive }
            .assign(to: &$isConnected)

        conversation.$isMuted
            .assign(to: &$isMuted)

        conversation.$agentState
            .assign(to: &$agentState)
    }
}


//sk_d9192372591f84ce3f92d3f9ca133dcb934b41c3bcb25dcc
