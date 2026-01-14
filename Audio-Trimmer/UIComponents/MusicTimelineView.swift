//
//  MusicTimelineView.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import SwiftUI
import ComposableArchitecture

struct MusicTimelineView: View {
    let store: StoreOf<TrimmerFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 10) {
                Text("Music Timeline")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Selected: \(time(store.selectionRange.lowerBound)) → \(time(store.selectionRange.upperBound))")
                    .foregroundStyle(.white.opacity(0.85))
                
                Text("Current: \(time(store.playhead))")
                    .foregroundStyle(.green)
                
                TimelineWaveform(
                    selection: store.selectionRange,
                    playhead: store.playhead
                ) { t in
                    store.send(.scrubbedTo(t))
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    
    private func time(_ percent: Double) -> String {
        let seconds = percent * store.totalLength
        return TimeFormatters.mmss(seconds)
    }
}

// MARK: - Fake waveform + scrub (fixed 10s window centered)
private struct TimelineWaveform: View {
    let selection: ClosedRange<Double>     // 固定 10 秒視窗（absolute range in 0~1）
    let playhead: Double                   // current (0~1)
    let onScrubTo: (Double) -> Void        // 拖動時間軸到某個百分比（0~1）
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let windowWidth = w * 0.62
            let windowX = (w - windowWidth) / 2
            
            let denom = max(0.0001, selection.upperBound - selection.lowerBound)
            let progress = (playhead - selection.lowerBound) / denom
            let clampedProgress = min(1, max(0, progress))
            
            let playheadX = windowX + windowWidth * clampedProgress
            
            ZStack(alignment: .leading) {
                // waveform placeholder
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.35))
                
                FakeWave()
                    .frame(width: w * 2) // 給它更寬，才有東西可滑
                    .padding(.horizontal, 10)
                    .opacity(0.9)
                    .offset(x: backgroundOffset(width: w, selectionStart: selection.lowerBound))
                    .animation(.linear(duration: 0.05), value: selection.lowerBound)
                    .clipped()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                .linearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .frame(width: max(20, windowWidth), height: h - 18)
                    .offset(x: windowX, y: 9)
                
                Rectangle()
                    .fill(.green)
                    .frame(width: 2, height: h - 18)
                    .offset(x: playheadX, y: 9)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let t = clamp01(Double(value.location.x / w))
                        onScrubTo(t)
                    }
            )
        }
        .frame(height: 92)
    }
    
    private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
    private func backgroundOffset(width: CGFloat, selectionStart: Double) -> CGFloat {
        let shiftFactor: CGFloat = 1.2  // 👈 你可以調整手感
        return -width * CGFloat(selectionStart) * shiftFactor
    }
    
}


private struct FakeWave: View {
    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<48, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.8))
                    .frame(width: 3, height: CGFloat((i * 17 % 60) + 8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
