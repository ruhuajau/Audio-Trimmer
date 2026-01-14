//
//  SettingsView.swift
//  Audio-Trimmer
//
//  Created by Ruby Jau on 2026/1/12.
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    @State private var timelineRatioText: String = ""
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case timelineRatio
    }
    
    var body: some View {
        WithPerceptionTracking {
            Form {
                Section("Track") {
                    Stepper(
                        value: Binding(
                            get: { store.totalTrackLength },
                            set: { store.send(.totalLengthChanged($0)) }
                        ),
                        in: 5...600,
                        step: 5
                    ) {
                        Text("Total length: \(Int(store.totalTrackLength))s")
                    }
                }
                
                Section("KeyTimes (preset)") {
                    Text("KeyTimes: \(store.keyTimes.map { String(format: "%.0f%%", $0 * 100) }.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Button("Use default key times") {
                        store.send(.setDefaultKeyTimesTapped)
                    }
                }
                
                Section("Timeline length ratio (optional)") {
                    TextField("e.g. 1.0 (no zoom in)", text: $timelineRatioText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .timelineRatio)
                        .onChange(of: timelineRatioText) { _, newValue in
                            store.send(.timelineLengthRatioChanged(newValue))
                        }
                    
                    Text("Leave empty to use default UI length.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button {
                        store.send(.startTapped)
                    } label: {
                        Text("Open Audio Trimmer")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear {
                if let v = store.timelineLengthRatio {
                    timelineRatioText = String(v)
                } else {
                    timelineRatioText = ""
                }
            }
        }
    }
}
