import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var selectedDay: String = HomeView.currentDayOfWeek()
    @State private var showingEditRoutine = false

    /// Returns the current day of week as a string (e.g., "Monday", "Tuesday")
    private static func currentDayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DaySelectorView(selectedDay: $selectedDay)
                    .padding(.bottom, 8)
                
                Divider()
                
                RoutineView(day: selectedDay)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        showingEditRoutine = true
                    }
                }
            }
            .sheet(isPresented: $showingEditRoutine) {
                EditRoutineView(day: selectedDay)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(SampleData.shared.modelContainer)
}
