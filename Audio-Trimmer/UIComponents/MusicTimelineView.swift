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
                  playhead: store.playhead,
                  timelineLengthRatio: store.timelineLengthRatio
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

// MARK: - Fake waveform + scrub
private struct TimelineWaveform: View {
    let selection: ClosedRange<Double>     // 0~1，固定 10 秒視窗（absolute）
    let playhead: Double                   // 0~1
    let timelineLengthRatio: Double?
    let onScrubTo: (Double) -> Void        // 更新 selectionStart（0~1）
    
    @State private var dragBaseStart: Double? = nil
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            let r = CGFloat(min(1, max(0.2, timelineLengthRatio ?? 1.0)))

            let base = 0.62 / r
            let windowWidth = w * min(0.92, max(0.35, base))
            let windowX = (w - windowWidth) / 2

            let windowRatio = max(0.0001, selection.upperBound - selection.lowerBound)
            let maxStart = max(0, 1 - windowRatio)
            
            let contentWidth = windowWidth / windowRatio
            

            let start = min(max(0, selection.lowerBound), maxStart)
            let contentOffsetX = windowX - contentWidth * start
            
            let denom = max(0.0001, selection.upperBound - selection.lowerBound)
            let progress = (playhead - selection.lowerBound) / denom
            let clampedProgress = min(1, max(0, progress))
            let playheadX = windowX + windowWidth * clampedProgress
            let progressWidth = windowWidth * clampedProgress
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.black.opacity(0.35))
                
                let barCount = max(10, Int(contentWidth / 7)) // 稍微增加間距讓菱形更明顯

                FakeWave(barCount: barCount, color: .white)
                    .frame(width: contentWidth, height: h - 18) // 👈 高度改為與選取框一致 (92 - 18 = 74)
                    .offset(x: contentOffsetX, y: 9)            // 👈 加入 y: 9，與選取框同步偏移
                    .opacity(0.9)
                    .clipped()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.35))
                    .frame(width: progressWidth, height: h - 18)
                    .offset(x: windowX, y: 9)
                    .mask(
                        RoundedRectangle(cornerRadius: 12)
                            .frame(width: windowWidth, height: h - 18)
                            .offset(x: windowX, y: 9)
                    )
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                .linearGradient(colors: [.orange, .pink, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing),
                                lineWidth: 3
                            )
                    )
                    .frame(width: windowWidth, height: h - 18)
                    .offset(x: windowX, y: 9)
                
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragBaseStart == nil {
                            dragBaseStart = start
                        }
                        guard let base = dragBaseStart else { return }
                        
                        let delta = Double(value.translation.width / contentWidth)
                        
                        let newStart = min(max(0, base - delta), maxStart)
                        onScrubTo(newStart)
                    }
                    .onEnded { _ in
                        dragBaseStart = nil
                    }
            )
        }
        .frame(height: 92)
    }
}

private struct FakeWave: View {
    let barCount: Int
    let color: Color
    
    private let diamondPattern: [CGFloat] = [
        0.2, 0.4, 0.6, 0.8, 0.6, 0.4
    ]
    
    var body: some View {
        // 移除 GeometryReader 避免不必要的排版計算
        HStack(alignment: .center, spacing: 4) { // 👈 確保 HStack 內部置中
            ForEach(0..<barCount, id: \.self) { i in
                let ratio = diamondPattern[i % diamondPattern.count]
                
                Capsule()
                    .fill(color)
                    // 使用比例來決定高度，確保不會超出父容器
                    .frame(width: 3, height: 50 * ratio)
                    // 這裡的 frame 是關鍵，它定義了單根 bar 的感應/佈局區域
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
    }
}
