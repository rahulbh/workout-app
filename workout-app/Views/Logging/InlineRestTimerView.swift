//
//  InlineRestTimerView.swift
//  workout-app
//
//  Compact inline rest timer that appears at bottom of workout logging screen
//

import SwiftUI

struct InlineRestTimerView: View {
    @State private var timerManager = TimerManager()

    let initialDuration: TimeInterval
    let onComplete: () -> Void
    let onSkip: () -> Void

    init(duration: TimeInterval = 90, onComplete: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}) {
        self.initialDuration = duration
        self.onComplete = onComplete
        self.onSkip = onSkip
    }

    var body: some View {
        HStack(spacing: 16) {
            // Timer display
            Text(timerManager.formattedTime)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .frame(minWidth: 80)

            Spacer()

            // Adjustment buttons
            HStack(spacing: 12) {
                Button {
                    timerManager.addTime(-15)
                } label: {
                    Text("-15s")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                .disabled(timerManager.timeRemaining <= 15)

                Button {
                    timerManager.addTime(15)
                } label: {
                    Text("+15s")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }

                Button {
                    timerManager.skip()
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .onAppear {
            timerManager.start(duration: initialDuration)
        }
        .onChange(of: timerManager.isComplete) { _, isComplete in
            if isComplete {
                onComplete()
            }
        }
        .onDisappear {
            timerManager.stop()
        }
    }
}

#Preview {
    VStack {
        Spacer()
        InlineRestTimerView(duration: 90)
            .background(Color(.systemBackground))
            .shadow(radius: 4)
    }
}
