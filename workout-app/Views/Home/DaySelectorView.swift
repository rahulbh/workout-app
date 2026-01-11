import SwiftUI
import SwiftData

struct DaySelectorView: View {
    @Binding var selectedDay: String
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    /// Returns today's day of week
    private var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    // Helper to get short name
    func shortName(for day: String) -> String {
        String(day.prefix(3))
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(shortName(for: day))
                            .font(.headline)

                        // Show dot indicator for today
                        if day == today {
                            Circle()
                                .fill(selectedDay == day ? Color.white : Color.blue)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(selectedDay == day ? Color.blue : Color(.systemGray5))
                    .foregroundColor(selectedDay == day ? .white : .primary)
                    .clipShape(Capsule())
                    .overlay(
                        // Border for today if not selected
                        Capsule()
                            .stroke(day == today && selectedDay != day ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedDay = day
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
