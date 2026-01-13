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

        Text("Selection: \(pct(store.selectionStart)) - \(pct(store.selectionEnd))")
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
  let selection: ClosedRange<Double>
  let playhead: Double
  let onTapKeyTime: (Double) -> Void

  var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(.white.opacity(0.12))
          .frame(height: 18)

        // selection highlight (yellow)
        Capsule()
          .fill(.yellow)
          .frame(
            width: max(2, geo.size.width * (selection.upperBound - selection.lowerBound)),
            height: 10
          )
          .offset(x: geo.size.width * selection.lowerBound)
          .padding(.leading, 0)
          .opacity(0.95)

        // playhead
        Capsule()
          .fill(.green)
          .frame(width: 2, height: 18)
          .offset(x: geo.size.width * playhead)

        // key time dots
        ForEach(keyTimes, id: \.self) { t in
          Circle()
            .fill(.pink)
            .frame(width: 16, height: 16)
            .offset(x: geo.size.width * t - 8)
            .contentShape(Rectangle().inset(by: -10))
            .onTapGesture { onTapKeyTime(t) }
        }
      }
    }
    .frame(height: 22)
  }
}
