import SwiftUI
import SwiftData

/// Chooses between the first-run onboarding flow and the main app
/// depending on whether a profile has been created yet.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}
