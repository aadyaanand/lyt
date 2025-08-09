import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            BatteryToolsView()
                .tabItem {
                    Image(systemName: "battery.100")
                    Text("Battery Tools")
                }
                .tag(1)
            
            CommunityView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Community")
                }
                .tag(2)
            
            ImpactView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Impact")
                }
                .tag(3)
            
            MakerView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver.fill")
                    Text("Maker")
                }
                .tag(4)
        }
        .accentColor(.voltLoopBlue)
        .navigationBarHidden(true)
    }
}

struct HomeDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var batteryManager: BatteryManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var communityManager: CommunityManager
    @State private var isEmergencyMode = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back, \(authManager.currentUser?.displayName ?? "User")")
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                            
                            Text("Ready to power your world sustainably?")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Emergency Mode Toggle
                        HStack {
                            Text("Emergency Mode")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Toggle("", isOn: $isEmergencyMode)
                                .toggleStyle(CustomToggleStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isEmergencyMode ? Color.voltLoopOrange : Color.secondaryBorder, lineWidth: 1)
                        )
                        .voltLoopGlow(color: isEmergencyMode ? .voltLoopOrange : .clear)
                        .padding(.horizontal, 20)
                        
                        // Quick Actions
                        VStack(spacing: 16) {
                            Text("Quick Actions")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                QuickActionCard(
                                    title: "Scan Battery",
                                    icon: "camera.fill",
                                    color: .voltLoopBlue
                                ) {
                                    // Navigate to scan
                                }
                                
                                QuickActionCard(
                                    title: "Find Drop-Off",
                                    icon: "mappin.circle.fill",
                                    color: .voltLoopYellow
                                ) {
                                    // Navigate to map
                                }
                                
                                QuickActionCard(
                                    title: "Request/Donate",
                                    icon: "arrow.triangle.2.circlepath",
                                    color: .voltLoopOrange
                                ) {
                                    // Navigate to community
                                }
                                
                                QuickActionCard(
                                    title: "View Impact",
                                    icon: "chart.bar.fill",
                                    color: .successColor
                                ) {
                                    // Navigate to impact
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Mini Leaderboard
                        VStack(spacing: 16) {
                            HStack {
                                Text("Community Leaderboard")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Button("View All") {
                                    // Navigate to full leaderboard
                                }
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.voltLoopBlue)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(0..<5) { index in
                                        LeaderboardCard(
                                            rank: index + 1,
                                            name: "User \(index + 1)",
                                            score: 1000 - (index * 150),
                                            isCurrentUser: index == 0
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Recent Activity
                        VStack(spacing: 16) {
                            Text("Recent Activity")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                ActivityCard(
                                    title: "Battery scanned",
                                    subtitle: "AA Duracell - Good condition",
                                    time: "2 hours ago",
                                    icon: "battery.100"
                                )
                                
                                ActivityCard(
                                    title: "Donation made",
                                    subtitle: "4 AA batteries to Community Center",
                                    time: "1 day ago",
                                    icon: "gift.fill"
                                )
                                
                                ActivityCard(
                                    title: "Impact milestone",
                                    subtitle: "Reached 50 batteries recycled",
                                    time: "3 days ago",
                                    icon: "leaf.fill"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("VoltLoop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.voltLoopBlue)
                    }
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .voltLoopGlow(color: color, radius: 10)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondaryBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LeaderboardCard: View {
    let rank: Int
    let name: String
    let score: Int
    let isCurrentUser: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundColor(rank <= 3 ? .voltLoopYellow : .secondaryText)
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(isCurrentUser ? .voltLoopBlue : .secondaryText)
                .voltLoopGlow(color: isCurrentUser ? .voltLoopBlue : .clear)
            
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.primaryText)
            
            Text("\(score)")
                .font(.system(size: 14, weight: .bold, design: .default))
                .foregroundColor(.voltLoopBlue)
        }
        .frame(width: 80, height: 100)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.voltLoopBlue : Color.secondaryBorder, lineWidth: 1)
        )
        .voltLoopGlow(color: isCurrentUser ? .voltLoopBlue : .clear)
    }
}

struct ActivityCard: View {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.voltLoopBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondaryBorder, lineWidth: 1)
        )
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Rectangle()
                .fill(configuration.isOn ? Color.voltLoopOrange : Color.secondaryBorder)
                .frame(width: 50, height: 30)
                .cornerRadius(15)
                .overlay(
                    Circle()
                        .fill(Color.voltLoopWhite)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthenticationManager())
            .environmentObject(BatteryManager())
            .environmentObject(LocationManager())
            .environmentObject(CommunityManager())
    }
} 