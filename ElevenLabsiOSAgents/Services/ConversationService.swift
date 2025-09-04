//
//  ConversationService.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/23/25.
//

import SwiftUI
import ElevenLabs
import Combine
import LiveKit

@MainActor
class ConversationService: ObservableObject {
    static let shared = ConversationService()
    
    @Published var messages: [Message] = []
    @Published var isConnected = false
    @Published var isMuted = false
    @Published var agentState: AgentState = .speaking
    // Current agent involved to conversation
    @Published var conversationAgent: Agent?
    // Tool handlers and triggers for UI display
    @Published var toolResults: [any ToolResult] = [] // storing client tools confirming to ToolResult protocol
    @Published var showToolResultCard: Bool = false
    
    private var conversation: Conversation?
    private var cancellables = Set<AnyCancellable>()
    // Custom configuration for the conversation
    private var config: ConversationConfig?
    
    // MARK: - Conversation management
    
    /// Assign selected agent to conversation
    func selectAgent(_ assistant: Agent) {
        conversationAgent = assistant
    }
    
    func startConversation() async {
        guard let agent = conversationAgent else { return }
        
        guard !agent.model_id.isEmpty else { return } // extra guard if model_id will be missconfigured in agent object
        
        // Set up dynamic variables which will be passed when conversation will boot
        // Learn more https://elevenlabs.io/docs/agents-platform/customization/personalization/dynamic-variables
        let dynamicVars: [String: String] = [
            "user_name": User.demo.name
        ]
        
        config = ConversationConfig(
            dynamicVariables: dynamicVars
        )
        
        do {
            conversation = try await ElevenLabs.startConversation(
                agentId: agent.model_id,
                config: config!
            )
            setupObservers()
        } catch {
            print("Failed to start conversation: \(error)")
        }
    }
    
    func endConversation() async {
        await conversation?.endConversation()
        conversation = nil
        conversationAgent = nil
        toolResults.removeAll() // Clear tool results
        showToolResultCard = false
        cancellables.removeAll()
        config = nil
    }
    
    func toggleMute() async {
        try? await conversation?.toggleMute()
    }
    
    private func setupObservers() {
        guard let conversation else { return }
        
        conversation.$messages
            .assign(to: &$messages)
        
        conversation.$state
            .map { $0.isActive }
            .assign(to: &$isConnected)
        
        conversation.$isMuted
            .assign(to: &$isMuted)
        
        conversation.$agentState
            .assign(to: &$agentState)
        
        // Observe tool calls and automatically handle them
        conversation.$pendingToolCalls
            .sink { toolCalls in
                for toolCall in toolCalls {
                    Task {
                        await self.handleToolCall(toolCall)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func agentStatus() -> String {
        if agentState == .speaking {
            return "\(conversationAgent?.name ?? "Unknown") is speaking"
        } else if agentState == .listening {
            return "\(conversationAgent?.name ?? "Unknown") is listening to you"
        }
        return ""
    }
    
    // MARK: - Tooling
    
    /// Universal handler of client tools sent back from agent - switch by registered tool names and assign related functions to execure them
    private func handleToolCall(_ toolCall: ClientToolCallEvent) async {
        do {
            let parameters = try toolCall.getParameters()
            
            switch toolCall.toolName {
            case "log_meal":
                await executeMealLogTool(toolCall: toolCall, parameters: parameters)
            case "optimize_sleep_schedule":
                await executeSleepOptimizationTool(toolCall: toolCall, parameters: parameters)
            default:
                // Handle unknown tools
                if toolCall.expectsResponse {
                    try await conversation?.sendToolResult(
                        for: toolCall.toolCallId,
                        result: "Unknown tool: \(toolCall.toolName)",
                        isError: true
                    )
                }
            }
        } catch {
            if toolCall.expectsResponse {
                try? await conversation?.sendToolResult(
                    for: toolCall.toolCallId,
                    result: error.localizedDescription,
                    isError: true
                )
            }
        }
    }
    
    /// Method which executes the meal log tool. Creates a `MealLog` object with payload from agent, then triggers UI display
    private func executeMealLogTool(toolCall: ClientToolCallEvent, parameters: [String: Any]) async {
        let protein = parameters["protein"] as? Int ?? 0
        let calories = parameters["calories"] as? Int ?? 0
        let carbs = parameters["carbs"] as? Int ?? 0
        let meal_name = parameters["meal_name"] as? String ?? "Unknown"
        let fats = parameters["fats"] as? Int ?? 0
        
        let mealLog = MealLog(
            tool_name: "log_meal",
            meal_name: meal_name,
            calories: calories,
            carbs: carbs,
            fats: fats,
            protein: protein
        )
        debugPrint(mealLog)
        
        // Add the tool result and trigger UI display
        await MainActor.run {
            toolResults.append(mealLog)
            withAnimation(.smooth) {
                showToolResultCard = true
            }
        }
    }
    
    /// Method which executes the meal log tool. Creates a `MealLog` object with payload from agent, then triggers UI display
    private func executeSleepOptimizationTool(toolCall: ClientToolCallEvent, parameters: [String: Any]) async {
        let wakeupTime = parameters["wakeup_time"] as? String ?? ""
        let ritual = parameters["pre_sleep_ritual"] as? String ?? ""
        let sleepTime = parameters["sleep_time"] as? String ?? ""
        
        let sleep_optimization = SleepOptimization(
            tool_name: "sleep_optimization",
            sleepTime: sleepTime,
            wakeupTime: wakeupTime,
            ritual: ritual
        )
        debugPrint(sleep_optimization)
        
        // Add the tool result and trigger UI display
        await MainActor.run {
            toolResults.append(sleep_optimization)
            withAnimation(.smooth) {
                showToolResultCard = true
            }
        }
    }
    
    /// Method to ask for tool result card dismiss
    func dismissToolResultCard() {
        withAnimation(.smooth) {
            showToolResultCard = false
        }
        toolResults.removeAll()
    }
    
    // MARK: - Debug methods
    
    /// Adding sample tool result and trigger UI to display the card
    func showDemoResultCard() {
        showToolResultCard.toggle()
        toolResults.append(SleepOptimization(tool_name: "sleep_optimization", sleepTime: "10:30 PM", wakeupTime:"6:45 AM", ritual: "3 minute wind-down focusing on breathing and a brief body scan"))
    }
}
