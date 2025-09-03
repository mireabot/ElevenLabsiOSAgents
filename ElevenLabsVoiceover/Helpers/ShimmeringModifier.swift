//
//  ShimmeringModifier.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 8/30/25.
//

import SwiftUI

struct Shimerring: ViewModifier {
    @State private var isShimmering = false

    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    colors: [
                        .black.opacity(0.4),
                        .black,
                        .black,
                        .black.opacity(0.4),
                    ],
                    startPoint: isShimmering ? UnitPoint(x: 1, y: 0) : UnitPoint(x: -1, y: 0),
                    endPoint: isShimmering ? UnitPoint(x: 2, y: 0) : UnitPoint(x: 0, y: 0)
                )
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isShimmering)
            )
            .onAppear {
                isShimmering = true
            }
    }
}

extension View {
    /// Creates a shimmering effect.
    func shimmering() -> some View {
        modifier(Shimerring())
    }
}
