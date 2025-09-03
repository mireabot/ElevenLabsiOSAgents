//
//  ToolResultCard.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 9/1/25.
//

import SwiftUI

struct ToolResultCard: View {
    let toolResult: any ToolResult
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let mealLog = toolResult as? MealLog {
                mealCard(log: mealLog)
            } else {
                defaultView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemFill).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.ultraThickMaterial, lineWidth: 1)
        )
        .overlay(alignment: .trailing) {
            Button(action: onDismiss) {
                Text("Save")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
    }
    
    @ViewBuilder
    private var defaultView: some View {
        Text("Unknown tool result")
            .font(.system(.subheadline))
            .foregroundColor(.secondary)
    }
    
    @ViewBuilder
    private func mealCard(log: MealLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(log.meal_name)
                .font(.system(.title3, weight: .semibold))
                .fontWidth(.expanded)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(log.calories)g")
                        .font(.system(.headline, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(log.protein)g")
                        .font(.system(.headline, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbs")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(log.carbs)g")
                        .font(.system(.headline, weight: .medium))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fats")
                        .font(.system(.subheadline, weight: .regular))
                        .foregroundStyle(.secondary)
                    Text("\(log.fats)g")
                        .font(.system(.headline, weight: .medium))
                }
            }
        }
    }
}

#Preview(body: {
    ToolResultCard(toolResult: MealLog(tool_name: "log_meal", meal_name: "Rice cake", calories: 229, carbs: 23, fats: 11, protein: 9)) {}
})
