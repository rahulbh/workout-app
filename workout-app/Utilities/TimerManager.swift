//
//  TimerManager.swift
//  workout-app
//
//  Timer logic for rest periods between sets
//

import Foundation
import SwiftUI
import AVFoundation

@Observable
class TimerManager {
    var timeRemaining: TimeInterval = 0
    var totalTime: TimeInterval = 0
    var isRunning: Bool = false
    var isComplete: Bool = false

    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1 - (timeRemaining / totalTime)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(duration: TimeInterval) {
        stop()
        totalTime = duration
        timeRemaining = duration
        isRunning = true
        isComplete = false

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 0.1
            } else {
                self.complete()
            }
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func resume() {
        guard !isRunning && timeRemaining > 0 else { return }
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 0.1
            } else {
                self.complete()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        timeRemaining = 0
        totalTime = 0
        isComplete = false
    }

    func skip() {
        stop()
        isComplete = true
    }

    func addTime(_ seconds: TimeInterval) {
        timeRemaining += seconds
        totalTime += seconds
    }

    private func complete() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        timeRemaining = 0
        isComplete = true
        playCompletionSound()
    }

    private func playCompletionSound() {
        // Play system sound for timer completion
        AudioServicesPlaySystemSound(1007) // Standard notification sound
    }
}
