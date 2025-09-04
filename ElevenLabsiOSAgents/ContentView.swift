//
//  ContentView.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/6/25.
//

import SwiftUI
import ElevenLabs
import Combine
import LiveKit
import FluidGradient

struct ConversationView: View {
    @StateObject private var viewModel = ConversationViewModel()
    
    var body: some View {
        ZStack {
            FluidGradient(blobs: [.black, .green, .blue, .purple, .teal],
                          highlights: [.mint, .cyan, .pink],
                          speed: 0.35,
                          blur: 0.55)
            .frame(width: 100, height: 50)
            .ignoresSafeArea()
            
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
                
                if viewModel.tools.isEmpty {
                    Text("No tools called")
                } else {
                    VStack {
                        Text("Pending Tools:")
                        ForEach(viewModel.tools, id: \.toolCallId) { tool in
                            HStack {
                                Text(tool.toolName)
                                Spacer()
//                                Button("Execute") {
//                                    Task {
//                                        await viewModel.handleToolCall(tool)
//                                    }
//                                }
//                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
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
    @Published var tools: [ClientToolCallEvent] = []
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
    
    // This function is called when the user wants to execute a tool manually
    func handleToolCall(_ toolCall: ClientToolCallEvent) async {
        do {
            let parameters = try toolCall.getParameters()

            let result = await executeClientTool(
                name: toolCall.toolName,
                parameters: parameters
            )

            if toolCall.expectsResponse {
                try await conversation?.sendToolResult(
                    for: toolCall.toolCallId,
                    result: result
                )
            } else {
                conversation?.markToolCallCompleted(toolCall.toolCallId)
            }
            
            // Remove the tool from the pending list
            tools.removeAll { $0.toolCallId == toolCall.toolCallId }
        } catch {
            // Handle tool execution errors
            if toolCall.expectsResponse {
                try? await conversation?.sendToolResult(
                    for: toolCall.toolCallId,
                    result: ["error": error.localizedDescription],
                    isError: true
                )
            }
            // Remove the tool from the pending list even if it failed
            tools.removeAll { $0.toolCallId == toolCall.toolCallId }
            print("Log failed")
        }
    }

    private func executeClientTool(name: String, parameters: [String: Any]) async -> String {
        switch name {
        case "logWorkout":
            let location = parameters["name"] as? String ?? "Unknown"
            print("Workout \(location) saved!")
            return "Workout \(location) saved!"

        case "get_time":
            return "Current time: \(Date().ISO8601Format())"

        case "alert_tool":
            return "User clicked something"

        default:
            return "Unknown tool: \(name)"
        }
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
        
        // Observe tool calls and automatically handle them
        conversation.$pendingToolCalls
            .sink { [weak self] toolCalls in
                // Update the tools array
                self?.tools = toolCalls
                
                Task {
                    for toolCall in toolCalls {
                        await self?.handleToolCall(toolCall)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

#Preview(body: {
    ConversationView()
})
