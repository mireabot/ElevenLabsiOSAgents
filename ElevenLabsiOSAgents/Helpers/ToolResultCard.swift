//
//  ToolResultCard.swift
//  ElevenLabsiOSAgents
//
//  Created by Mikhail Kolkov on 9/1/25.
//

import SwiftUI

struct ToolResultCard: View {
    let toolResult: any ToolResult
    let onDismiss: () -> Void
    
    private var buttonText: String {
        if toolResult is MealLog {
            return "Save"
        } else if toolResult is SleepOptimization {
            return "Dismiss"
        }
        return "OK"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: onDismiss) {
                Text(buttonText)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 12) {
                if let mealLog = toolResult as? MealLog {
                    mealCard(result: mealLog)
                } else if let sleepOptimization = toolResult as? SleepOptimization {
                    sleepOptimizationCard(result: sleepOptimization)
                } else {
                    defaultView
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(uiColor: .secondarySystemFill).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.ultraThickMaterial, lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var defaultView: some View {
        Text("Unknown tool result")
            .font(.system(.subheadline))
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private func mealCard(result: MealLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.meal_name)
                .font(.system(.title3, weight: .semibold))
                .fontWidth(.expanded)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(result.calories)g")
                        .font(.system(.headline, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(result.protein)g")
                        .font(.system(.headline, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbs")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(result.carbs)g")
                        .font(.system(.headline, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fats")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(result.fats)g")
                        .font(.system(.headline, weight: .medium))
                }
            }
        }
    }
    
    @ViewBuilder
    private func sleepOptimizationCard(result: SleepOptimization) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your night plan")
                .font(.system(.title3, weight: .semibold))
                .fontWidth(.expanded)
            
            ZStack {
                HStack {
                    VStack(alignment: .center, spacing: 2) {
                        Text(result.sleepTime)
                            .font(.system(.title3, weight: .medium))
                        Text("Bed Time")
                            .font(.system(.subheadline, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(result.wakeupTime)
                            .font(.system(.title3, weight: .medium))
                        Text("Wake Up Time")
                            .font(.system(.subheadline, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Image(systemName: "bed.double.fill")
                    .font(.system(.title3, weight: .regular))
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.teal)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tip before bed")
                    .font(.system(.footnote, weight: .regular))
                    .foregroundStyle(.tertiary)
                Text(result.ritual)
                    .font(.system(.subheadline, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

#Preview(body: {
    VStack {
        ToolResultCard(toolResult: MealLog(tool_name: "log_meal", meal_name: "Rice cake", calories: 229, carbs: 23, fats: 11, protein: 9)) {}
        
        ToolResultCard(toolResult: SleepOptimization(tool_name: "sleep_optimization", sleepTime: "10:30 PM", wakeupTime:"6:45 AM", ritual: "3 minute wind-down focusing on breathing and a brief body scan")) {}
    }
    .padding(.horizontal)
    .preferredColorScheme(.dark)
})
