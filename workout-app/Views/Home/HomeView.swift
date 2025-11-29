import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var selectedDay: String = "Monday"
    @State private var showingEditRoutine = false
    
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
