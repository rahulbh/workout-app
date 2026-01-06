import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var hasSeededDatabase = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            MetricsView()
                .tabItem {
                    Label("Metrics", systemImage: "chart.bar.xaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .onAppear {
            if !hasSeededDatabase {
                DatabaseSeeder.seedExercisesIfNeeded(context: modelContext)
                hasSeededDatabase = true
            }
        }
    }
}

#Preview {
    ContentView().modelContainer(SampleData.shared.modelContainer)
}
