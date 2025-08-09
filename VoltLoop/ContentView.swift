import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isShowingWelcome = true
    
    var body: some View {
        Group {
            if isShowingWelcome && !authManager.isAuthenticated {
                WelcomeView(isShowingWelcome: $isShowingWelcome)
            } else if !authManager.isAuthenticated {
                AuthenticationView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: isShowingWelcome)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager())
            .environmentObject(BatteryManager())
            .environmentObject(LocationManager())
            .environmentObject(CommunityManager())
    }
} 