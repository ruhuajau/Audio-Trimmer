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

        Text("Selected: \(time(store.selectionStart)) → \(time(store.selectionEnd))")
          .foregroundStyle(.white.opacity(0.85))

        Text("Current: \(time(store.playhead))")
          .foregroundStyle(.green)

        TimelineWaveform(
          selectionStart: store.selectionStart,
          selectionEnd: store.selectionEnd,
          playhead: store.playhead
        ) { newStart, newEnd in
          store.send(.selectionDragged(start: newStart, end: newEnd))
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

// MARK: - Fake waveform + draggable selection
private struct TimelineWaveform: View {
  let selectionStart: Double
  let selectionEnd: Double
  let playhead: Double
  let onDragSelection: (Double, Double) -> Void

  @GestureState private var dragDelta: CGFloat = 0
  @State private var activeDrag: DragMode? = nil

  enum DragMode { case whole, start, end }

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      let h = geo.size.height

      ZStack(alignment: .leading) {
        // waveform placeholder
        RoundedRectangle(cornerRadius: 14)
          .fill(.black.opacity(0.35))

        FakeWave()
          .padding(.horizontal, 10)
          .opacity(0.9)

        // selection overlay
        let x1 = w * selectionStart
        let x2 = w * selectionEnd

        RoundedRectangle(cornerRadius: 12)
          .fill(.white.opacity(0.22))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(.linearGradient(
                colors: [.orange, .pink, .purple],
                startPoint: .leading,
                endPoint: .trailing
              ), lineWidth: 3)
          )
          .frame(width: max(20, x2 - x1), height: h - 18)
          .offset(x: x1, y: 9)

        // playhead
        Rectangle()
          .fill(.green)
          .frame(width: 2, height: h - 18)
          .offset(x: w * playhead, y: 9)
      }
      .contentShape(Rectangle())
      .gesture(dragGesture(width: w))
    }
    .frame(height: 92)
  }

  private func dragGesture(width: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let x = value.location.x
        let t = clamp01(Double(x / width))

        if activeDrag == nil {
          let start = selectionStart
          let end = selectionEnd
          let threshold = 0.03
          if abs(t - start) < threshold { activeDrag = .start }
          else if abs(t - end) < threshold { activeDrag = .end }
          else { activeDrag = .whole }
        }

        switch activeDrag {
        case .start:
          onDragSelection(t, selectionEnd)
        case .end:
          onDragSelection(selectionStart, t)
        case .whole:
          let dx = Double(value.translation.width / width)
          let len = selectionEnd - selectionStart
          let newStart = clamp01(selectionStart + dx)
          let newEnd = clamp01(newStart + len)
          onDragSelection(newStart, newEnd)
        case .none:
          break
        }
      }
      .onEnded { _ in
        activeDrag = nil
      }
  }

  private func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }
}

private struct FakeWave: View {
  var body: some View {
    HStack(alignment: .center, spacing: 3) {
      ForEach(0..<48, id: \.self) { i in
        RoundedRectangle(cornerRadius: 2)
          .fill(.white.opacity(0.8))
          .frame(width: 3, height: CGFloat((i * 13 % 40) + 12))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}
