import SwiftUI
import Charts

struct ImpactView: View {
    @EnvironmentObject var batteryManager: BatteryManager
    @State private var selectedTimeframe: Timeframe = .month
    @State private var showingBadges = false
    @State private var showingLeaderboard = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.successColor)
                                .voltLoopGlow(color: .successColor, radius: 20)
                            
                            Text("Your Impact")
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                            
                            Text("Track your environmental contributions")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Impact Stats
                        VStack(spacing: 16) {
                            Text("Environmental Impact")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ImpactStatCard(
                                    title: "Batteries Recycled",
                                    value: "\(batteryManager.scannedBatteries.filter { $0.healthStatus == .recycleASAP }.count)",
                                    icon: "battery.100",
                                    color: .voltLoopOrange
                                )
                                
                                ImpactStatCard(
                                    title: "Batteries Reused",
                                    value: "\(batteryManager.scannedBatteries.filter { $0.healthStatus == .reusable }.count)",
                                    icon: "arrow.clockwise",
                                    color: .successColor
                                )
                                
                                ImpactStatCard(
                                    title: "CO₂ Avoided",
                                    value: "\(calculateCO2Avoided()) kg",
                                    icon: "leaf.fill",
                                    color: .successColor
                                )
                                
                                ImpactStatCard(
                                    title: "E-Waste Diverted",
                                    value: "\(calculateEWasteDiverted()) kg",
                                    icon: "trash.fill",
                                    color: .voltLoopBlue
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Progress Rings
                        VStack(spacing: 16) {
                            Text("Progress Goals")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 20) {
                                ProgressRingView(
                                    title: "Recycling",
                                    progress: calculateRecyclingProgress(),
                                    color: .voltLoopOrange
                                )
                                
                                ProgressRingView(
                                    title: "Reuse",
                                    progress: calculateReuseProgress(),
                                    color: .successColor
                                )
                                
                                ProgressRingView(
                                    title: "Community",
                                    progress: calculateCommunityProgress(),
                                    color: .voltLoopBlue
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Badges Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Badges")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showingBadges = true
                                }
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.voltLoopBlue)
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(getEarnedBadges().prefix(5)) { badge in
                                        BadgeCard(badge: badge)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Leaderboard Preview
                        VStack(spacing: 16) {
                            HStack {
                                Text("Leaderboard")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                Spacer()
                                
                                Button("View All") {
                                    showingLeaderboard = true
                                }
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.voltLoopBlue)
                            }
                            
                            VStack(spacing: 12) {
                                ForEach(0..<3) { index in
                                    LeaderboardRow(
                                        rank: index + 1,
                                        name: "User \(index + 1)",
                                        score: 1000 - (index * 150),
                                        isCurrentUser: index == 0
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Impact Chart
                        VStack(spacing: 16) {
                            Text("Impact Over Time")
                                .font(.system(size: 20, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Timeframe Selector
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                    Text(timeframe.rawValue.capitalized)
                                        .tag(timeframe)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            // Chart Placeholder
                            ImpactChartView(timeframe: selectedTimeframe)
                                .frame(height: 200)
                                .padding(.vertical, 20)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Impact")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingBadges) {
            BadgesView()
        }
        .sheet(isPresented: $showingLeaderboard) {
            LeaderboardView()
        }
    }
    
    // MARK: - Calculation Methods
    private func calculateCO2Avoided() -> Int {
        let recycledCount = batteryManager.scannedBatteries.filter { $0.healthStatus == .recycleASAP }.count
        return recycledCount * 2 // 2kg CO2 per battery
    }
    
    private func calculateEWasteDiverted() -> Int {
        let recycledCount = batteryManager.scannedBatteries.filter { $0.healthStatus == .recycleASAP }.count
        return recycledCount * 50 // 50g per battery
    }
    
    private func calculateRecyclingProgress() -> Double {
        let recycledCount = batteryManager.scannedBatteries.filter { $0.healthStatus == .recycleASAP }.count
        return min(Double(recycledCount) / 10.0, 1.0) // Goal: 10 batteries
    }
    
    private func calculateReuseProgress() -> Double {
        let reusedCount = batteryManager.scannedBatteries.filter { $0.healthStatus == .reusable }.count
        return min(Double(reusedCount) / 20.0, 1.0) // Goal: 20 batteries
    }
    
    private func calculateCommunityProgress() -> Double {
        // Mock community contribution
        return 0.7
    }
    
    private func getEarnedBadges() -> [Badge] {
        return [
            Badge(id: "1", name: "First Scan", description: "Scanned your first battery", icon: "battery.25", isEarned: true),
            Badge(id: "2", name: "Recycler", description: "Recycled 5 batteries", icon: "leaf.fill", isEarned: true),
            Badge(id: "3", name: "Community Helper", description: "Helped 3 community members", icon: "person.3.fill", isEarned: true),
            Badge(id: "4", name: "Power Saver", description: "Reused 10 batteries", icon: "arrow.clockwise", isEarned: false),
            Badge(id: "5", name: "Eco Warrior", description: "Avoided 50kg of CO2", icon: "shield.fill", isEarned: false)
        ]
    }
}

enum Timeframe: String, CaseIterable {
    case week = "week"
    case month = "month"
    case year = "year"
}

struct ImpactStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .voltLoopGlow(color: color, radius: 10)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.secondaryText)
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
}

struct ProgressRingView: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondaryBorder, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.primaryText)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.secondaryText)
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.icon)
                .font(.system(size: 32))
                .foregroundColor(badge.isEarned ? .voltLoopYellow : .secondaryText)
                .voltLoopGlow(color: badge.isEarned ? .voltLoopYellow : .clear)
            
            Text(badge.name)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(badge.isEarned ? .primaryText : .secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 80)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(badge.isEarned ? Color.voltLoopYellow : Color.secondaryBorder, lineWidth: 1)
        )
        .opacity(badge.isEarned ? 1.0 : 0.5)
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let score: Int
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundColor(rank <= 3 ? .voltLoopYellow : .secondaryText)
                .frame(width: 30)
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isCurrentUser ? .voltLoopBlue : .secondaryText)
                .voltLoopGlow(color: isCurrentUser ? .voltLoopBlue : .clear)
            
            Text(name)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundColor(.primaryText)
            
            Spacer()
            
            Text("\(score)")
                .font(.system(size: 16, weight: .bold, design: .default))
                .foregroundColor(.voltLoopBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.voltLoopBlue : Color.secondaryBorder, lineWidth: 1)
        )
    }
}

struct ImpactChartView: View {
    let timeframe: Timeframe
    
    var body: some View {
        VStack {
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.voltLoopBlue)
                        
                        Text("Impact Chart")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                    }
                )
        }
    }
}

struct Badge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let isEarned: Bool
}

struct ImpactView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactView()
            .environmentObject(BatteryManager())
    }
} 