import SwiftUI
import FirebaseCore

@main
struct GuineaDayApp: App {
    @State private var auth      = AuthService()
    @State private var household = HouseholdService()
    @State private var store     = FirestoreService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(auth)
                .environment(household)
                .environment(store)
                .fontDesign(.rounded)
                .tint(Color.inkBrown)
        }
    }

    @ViewBuilder
    var rootView: some View {
        if !auth.isSignedIn {
            // Not signed in — show Apple Sign-In screen
            SignInView()
        } else if household.householdId == nil {
            // Signed in but no household yet
            HouseholdSetupView()
                .task {
                    // Try to restore household from Firestore (e.g. on new device)
                    if let uid = auth.user?.uid {
                        await household.restoreHousehold(uid: uid)
                    }
                }
        } else {
            // Ready — start live data and show main app
            ContentView()
                .task {
                    if let hid = household.householdId {
                        store.start(householdId: hid)
                        ImageStorageService.shared.configure(householdId: hid)
                    }
                }
        }
    }
}
