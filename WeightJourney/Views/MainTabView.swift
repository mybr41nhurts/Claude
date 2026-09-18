import SwiftUI

struct MainTabView: View {
    var profile: UserProfile
    @State private var isPresentingLogSheet = false

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(profile: profile, isPresentingLogSheet: $isPresentingLogSheet)
            }
            .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent") }

            NavigationStack {
                TrendsView(profile: profile)
            }
            .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                GoalsView(profile: profile)
            }
            .tabItem { Label("Goals", systemImage: "target") }

            NavigationStack {
                HistoryView(profile: profile)
            }
            .tabItem { Label("History", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                SettingsView(profile: profile)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .sheet(isPresented: $isPresentingLogSheet) {
            LogWeightView(profile: profile)
        }
    }
}
