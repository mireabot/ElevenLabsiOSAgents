//
//  VoiceVisualizer.swift
//  ElevenLabsVoiceover
//
//  Created by Mikhail Kolkov on 9/3/25.
//

import SwiftUI
import LiveKit

public struct BarAudioVisualizer: View {
    public let barCount: Int
    public let barColor: Color
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let barMinOpacity: Double
    public let isCentered: Bool

    private let agentState: AgentState

    @StateObject private var audioProcessor: AudioProcessor

    @State private var animationProperties: PhaseAnimationProperties
    @State private var animationPhase: Int = 0
    @State private var animationTask: Task<Void, Never>?

    public init(audioTrack: AudioTrack?,
                agentState: AgentState = .idle,
                barColor: Color = .primary,
                barCount: Int = 5,
                barCornerRadius: CGFloat = 100,
                barSpacingFactor: CGFloat = 0.015,
                barMinOpacity: CGFloat = 0.16,
                isCentered: Bool = true)
    {
        self.agentState = agentState

        self.barColor = barColor
        self.barCount = barCount
        self.barCornerRadius = barCornerRadius
        self.barSpacingFactor = barSpacingFactor
        self.barMinOpacity = Double(barMinOpacity)
        self.isCentered = isCentered

        _audioProcessor = StateObject(wrappedValue: AudioProcessor(track: audioTrack,
                                                                   bandCount: barCount,
                                                                   isCentered: isCentered))

        animationProperties = PhaseAnimationProperties(barCount: barCount)
    }

    public var body: some View {
        GeometryReader { geometry in
            let highlightingSequence = animationProperties.highlightingSequence(agentState: agentState)
            let highlighted = highlightingSequence[animationPhase % highlightingSequence.count]

            bars(geometry: geometry, highlighted: highlighted)
                .onAppear {
                    startAnimation(duration: animationProperties.duration(agentState: agentState))
                }
                .onDisappear {
                    stopAnimation()
                }
                .onChange(of: agentState) { _, newState in
                    startAnimation(duration: animationProperties.duration(agentState: newState))
                }
                .animation(.easeInOut, value: animationPhase)
                .animation(.easeInOut(duration: 0.3), value: agentState)
        }
    }

    @ViewBuilder
    private func bars(geometry: GeometryProxy, highlighted: PhaseAnimationProperties.HighlightedBars) -> some View {
        let totalSpacing = geometry.size.width * barSpacingFactor * CGFloat(barCount + 1)
        let availableWidth = geometry.size.width - totalSpacing
        let barWidth = availableWidth / CGFloat(barCount)
        let barMinHeight = barWidth // Use bar width as minimum height for square proportions

        HStack(alignment: .center, spacing: geometry.size.width * barSpacingFactor) {
            ForEach(0 ..< audioProcessor.bands.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: barMinHeight)
                    .fill(barColor)
                    .opacity(highlighted.contains(index) ? 1 : barMinOpacity)
                    .frame(
                        width: barWidth,
                        height: (geometry.size.height - barMinHeight) * CGFloat(audioProcessor.bands[index]) + barMinHeight,
                        alignment: .center
                    )
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(width: geometry.size.width)
    }

    private func startAnimation(duration: TimeInterval) {
        animationTask?.cancel()
        animationPhase = 0
        animationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
                animationPhase += 1
            }
        }
    }

    private func stopAnimation() {
        animationTask?.cancel()
    }
}

extension BarAudioVisualizer {
    private struct PhaseAnimationProperties {
        typealias HighlightedBars = Set<Int>

        private let barCount: Int
        private let veryLongDuration: TimeInterval = 1000

        init(barCount: Int) {
            self.barCount = barCount
        }

        func duration(agentState: AgentState) -> TimeInterval {
            switch agentState {
            case .initializing: 2 / Double(barCount)
            case .listening: 0.5
            case .thinking: 0.15
            case .speaking: veryLongDuration
            default: veryLongDuration
            }
        }

        func highlightingSequence(agentState: AgentState) -> [HighlightedBars] {
            switch agentState {
            case .initializing: (0 ..< barCount).map { HighlightedBars([$0, barCount - 1 - $0]) }
            case .thinking: Array((0 ..< barCount) + (0 ..< barCount).reversed()).map { HighlightedBars([$0]) }
            case .listening: barCount % 2 == 0 ? [[(barCount / 2) - 1, barCount / 2], []] : [[barCount / 2], []]
            case .speaking: [HighlightedBars(0 ..< barCount)]
            case .idle: [[]]
            }
        }
    }
}
