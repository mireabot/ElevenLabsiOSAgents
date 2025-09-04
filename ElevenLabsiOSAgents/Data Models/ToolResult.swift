//
//  ToolResult.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 8/31/25.
//

import Foundation

/// Protocol for any data objects which will be used in tool result population
protocol ToolResult {
    var tool_name: String { get }
}

/// Object which represents a meal log tool result
struct MealLog: ToolResult {
    let tool_name: String
    let meal_name: String
    let calories: Int
    let carbs: Int
    let fats: Int
    let protein: Int
}

/// Object which represents a sleep optimization tool result
struct SleepOptimization: ToolResult {
    let tool_name: String
    let sleepTime: String
    let wakeupTime: String
    let ritual: String
}
