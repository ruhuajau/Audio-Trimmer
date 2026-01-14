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
  let selection: ClosedRange<Double>
  let playhead: Double
  let onTapKeyTime: (Double) -> Void

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width

        ZStack(alignment: .leading) {
          Capsule()
            .fill(.white.opacity(0.12))
            .frame(height: 18)
            .allowsHitTesting(false)

          Capsule()
            .fill(.yellow)
            .frame(
              width: max(2, w * (selection.upperBound - selection.lowerBound)),
              height: 10
            )
            .offset(x: w * selection.lowerBound)
            .opacity(0.95)
            .allowsHitTesting(false)

            ForEach(keyTimes, id: \.self) { t in
              ZStack {
                Circle()
                  .fill(.pink)
                  .frame(width: 16, height: 16)
              }
              .offset(x: w * t - 8)
              .highPriorityGesture(
                TapGesture().onEnded {
                  print("Tapped:", t)
                  onTapKeyTime(t)
                }
              )
            }
        }

    }
    .frame(height: 22)
  }
}
