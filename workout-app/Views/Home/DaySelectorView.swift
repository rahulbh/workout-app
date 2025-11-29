import SwiftUI
import SwiftData

struct DaySelectorView: View {
    @Binding var selectedDay: String
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    // Helper to get short name
    func shortName(for day: String) -> String {
        String(day.prefix(3))
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { day in
                    Text(shortName(for: day))
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(selectedDay == day ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedDay == day ? .white : .primary)
                        .clipShape(Capsule())
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
