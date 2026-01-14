//
//  KeyTimeSelectionView.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import SwiftUI
import ComposableArchitecture

struct KeyTimeSelectionView: View {
  let store: StoreOf<TrimmerFeature>

  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: 10) {
        Text("KeyTime Selection")
          .font(.headline)
          .foregroundStyle(.white)

        Text("Selection: \(pct(store.selectionRange.lowerBound)) - \(pct(store.selectionRange.upperBound))")
          .foregroundStyle(.white.opacity(0.85))
                           
        Text("Current: \(pct(store.playhead))")
          .foregroundStyle(.green)

        KeyTimeBar(
          keyTimes: store.keyTimes,
          selection: store.selectionRange,
          playhead: store.playhead
        ) { tapped in
          store.send(.keyTimeTapped(tapped))
        }
      }
      .padding(16)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 18))
    }
  }

  private func pct(_ x: Double) -> String {
    String(format: "%.1f%%", x * 100)
  }
}

// MARK: - Bar
private struct KeyTimeBar: View {
  let keyTimes: [Double]
  let selection: ClosedRange<Double>   // absolute 0~1
  let playhead: Double                 // absolute 0~1
  let onTapKeyTime: (Double) -> Void

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width

      // 固定視窗置中（視覺用）
      let windowWidth = w * 0.55
      let windowX = (w - windowWidth) / 2

      // playhead 在 selection 內的相對位置
      let denom = max(0.0001, selection.upperBound - selection.lowerBound)
      let progress = (playhead - selection.lowerBound) / denom
      let clampedProgress = min(1, max(0, progress))
      let playheadX = windowX + windowWidth * clampedProgress

      ZStack(alignment: .leading) {
        Capsule()
          .fill(.white.opacity(0.12))
          .frame(height: 18)

        // ✅ 黃色 selection 框固定置中
        Capsule()
          .fill(.yellow)
          .frame(width: max(2, windowWidth), height: 10)
          .offset(x: windowX)
          .opacity(0.95)

        // ✅ 綠線：在黃色框內移動
        Capsule()
          .fill(.green)
          .frame(width: 2, height: 18)
          .offset(x: playheadX)

        // ✅ key time dots：依然是 absolute 位置（整條 bar 上）
        ForEach(keyTimes, id: \.self) { t in
          Circle()
            .fill(.pink)
            .frame(width: 16, height: 16)
            .offset(x: w * t - 8)
            .contentShape(Rectangle().inset(by: -10))
            .onTapGesture { onTapKeyTime(t) }
        }
      }
    }
    .frame(height: 22)
  }
}

