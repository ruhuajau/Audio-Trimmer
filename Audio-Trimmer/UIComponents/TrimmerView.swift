//
//  TrimmerView.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import SwiftUI
import ComposableArchitecture

struct TrimmerView: View {
  let store: StoreOf<TrimmerFeature>

  var body: some View {
    WithPerceptionTracking {
      ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 18) {
          KeyTimeSelectionView(store: store)
          MusicTimelineView(store: store)

          HStack(spacing: 16) {
            Button {
              store.send(.playPauseTapped)
            } label: {
              Text(store.isPlaying ? "Pause" : "Play")
                .frame(width: 120, height: 44)
            }
            .buttonStyle(.borderedProminent)

            Button {
              store.send(.resetTapped)
            } label: {
              Text("Reset")
                .frame(width: 120, height: 44)
            }
            .buttonStyle(.bordered)
          }
          .padding(.top, 6)
        }
        .padding(.horizontal, 16)
      }
      .navigationTitle("Audio Trimmer")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
