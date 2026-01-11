//
//  RestTimerView.swift
//  workout-app
//
//  Circular rest timer overlay shown after completing a set
//

import SwiftUI

struct RestTimerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var timerManager = TimerManager()

    let initialDuration: TimeInterval
    let onComplete: () -> Void

    init(duration: TimeInterval = 90, onComplete: @escaping () -> Void = {}) {
        self.initialDuration = duration
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Title
            Text("Rest Timer")
                .font(.title2)
                .bold()

            // Circular Progress
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 200, height: 200)

                // Progress circle
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: timerManager.progress)

                // Time display
                VStack(spacing: 4) {
                    Text(timerManager.formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))

                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Time adjustment buttons
            HStack(spacing: 20) {
                Button {
                    timerManager.addTime(-15)
                } label: {
                    Text("-15s")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                .disabled(timerManager.timeRemaining <= 15)

                Button {
                    timerManager.addTime(15)
                } label: {
                    Text("+15s")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }

                Button {
                    timerManager.addTime(30)
                } label: {
                    Text("+30s")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 20) {
                // Skip button
                Button {
                    timerManager.skip()
                    onComplete()
                    dismiss()
                } label: {
                    Text("Skip")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }

                // Done / Pause button
                Button {
                    if timerManager.isRunning {
                        timerManager.pause()
                    } else if timerManager.timeRemaining > 0 {
                        timerManager.resume()
                    } else {
                        onComplete()
                        dismiss()
                    }
                } label: {
                    Text(timerManager.isRunning ? "Pause" : (timerManager.timeRemaining > 0 ? "Resume" : "Done"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            timerManager.start(duration: initialDuration)
        }
        .onChange(of: timerManager.isComplete) { _, isComplete in
            if isComplete {
                onComplete()
                // Auto-dismiss after a short delay when timer completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
        .onDisappear {
            timerManager.stop()
        }
    }
}

#Preview {
    RestTimerView(duration: 10)
}
