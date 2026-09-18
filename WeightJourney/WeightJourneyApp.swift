import SwiftUI
import SwiftData

@main
struct WeightJourneyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WeightEntry.self,
            UserProfile.self,
            WeightGoal.self,
            Milestone.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
