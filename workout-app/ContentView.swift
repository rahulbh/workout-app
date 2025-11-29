import SwiftUI
import SwiftData

struct ContentView: View {
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
        }
    }
}

#Preview {
    ContentView().modelContainer(SampleData.shared.modelContainer)
}
