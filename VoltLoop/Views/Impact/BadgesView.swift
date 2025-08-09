import SwiftUI

struct BadgesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: BadgeCategory = .all
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.voltLoopYellow)
                                .voltLoopGlow(color: .voltLoopYellow, radius: 20)
                            
                            Text("Badges & Achievements")
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                            
                            Text("Track your progress and unlock achievements")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Category Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(BadgeCategory.allCases, id: \.self) { category in
                                    CategoryChip(
                                        title: category.rawValue,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Badges Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(getFilteredBadges()) { badge in
                                BadgeDetailCard(badge: badge)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.voltLoopBlue)
                }
            }
        }
    }
    
    private func getFilteredBadges() -> [BadgeDetail] {
        let allBadges = getAllBadges()
        
        if selectedCategory == .all {
            return allBadges
        } else {
            return allBadges.filter { $0.category == selectedCategory }
        }
    }
    
    private func getAllBadges() -> [BadgeDetail] {
        return [
            // Recycling Badges
            BadgeDetail(
                id: "1",
                name: "First Scan",
                description: "Scanned your first battery",
                icon: "battery.25",
                category: .recycling,
                isEarned: true,
                progress: 1.0,
                requirement: "Scan 1 battery"
            ),
            BadgeDetail(
                id: "2",
                name: "Recycler",
                description: "Recycled 5 batteries",
                icon: "leaf.fill",
                category: .recycling,
                isEarned: true,
                progress: 1.0,
                requirement: "Recycle 5 batteries"
            ),
            BadgeDetail(
                id: "3",
                name: "Eco Warrior",
                description: "Recycled 50 batteries",
                icon: "shield.fill",
                category: .recycling,
                isEarned: false,
                progress: 0.3,
                requirement: "Recycle 50 batteries"
            ),
            
            // Community Badges
            BadgeDetail(
                id: "4",
                name: "Community Helper",
                description: "Helped 3 community members",
                icon: "person.3.fill",
                category: .community,
                isEarned: true,
                progress: 1.0,
                requirement: "Help 3 community members"
            ),
            BadgeDetail(
                id: "5",
                name: "Power Giver",
                description: "Donated 10 batteries",
                icon: "gift.fill",
                category: .community,
                isEarned: false,
                progress: 0.6,
                requirement: "Donate 10 batteries"
            ),
            BadgeDetail(
                id: "6",
                name: "Emergency Responder",
                description: "Responded to 5 emergency requests",
                icon: "exclamationmark.triangle.fill",
                category: .community,
                isEarned: false,
                progress: 0.2,
                requirement: "Respond to 5 emergency requests"
            ),
            
            // Impact Badges
            BadgeDetail(
                id: "7",
                name: "CO₂ Saver",
                description: "Avoided 25kg of CO₂ emissions",
                icon: "leaf.circle.fill",
                category: .impact,
                isEarned: false,
                progress: 0.8,
                requirement: "Avoid 25kg of CO₂"
            ),
            BadgeDetail(
                id: "8",
                name: "Metal Preserver",
                description: "Preserved 100g of rare metals",
                icon: "atom",
                category: .impact,
                isEarned: false,
                progress: 0.4,
                requirement: "Preserve 100g of rare metals"
            ),
            
            // Maker Badges
            BadgeDetail(
                id: "9",
                name: "DIY Master",
                description: "Completed 5 maker projects",
                icon: "wrench.and.screwdriver.fill",
                category: .maker,
                isEarned: false,
                progress: 0.6,
                requirement: "Complete 5 maker projects"
            ),
            BadgeDetail(
                id: "10",
                name: "Teacher's Helper",
                description: "Supported 3 classroom projects",
                icon: "graduationcap.fill",
                category: .maker,
                isEarned: false,
                progress: 0.33,
                requirement: "Support 3 classroom projects"
            )
        ]
    }
}

struct BadgeDetailCard: View {
    let badge: BadgeDetail
    
    var body: some View {
        VStack(spacing: 16) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(badge.isEarned ? Color.voltLoopYellow.opacity(0.2) : Color.secondaryBackground)
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 32))
                    .foregroundColor(badge.isEarned ? .voltLoopYellow : .secondaryText)
                    .voltLoopGlow(color: badge.isEarned ? .voltLoopYellow : .clear)
            }
            
            // Badge Info
            VStack(spacing: 8) {
                Text(badge.name)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(badge.description)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Progress Bar
                if !badge.isEarned {
                    VStack(spacing: 4) {
                        ProgressView(value: badge.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .voltLoopBlue))
                            .scaleEffect(y: 0.5)
                        
                        Text(badge.requirement)
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.successColor)
                        
                        Text("Earned")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .foregroundColor(.successColor)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(badge.isEarned ? Color.voltLoopYellow : Color.secondaryBorder, lineWidth: 1)
        )
        .opacity(badge.isEarned ? 1.0 : 0.7)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(isSelected ? .voltLoopBlack : .primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.voltLoopBlue : Color.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.voltLoopBlue : Color.secondaryBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Models
struct BadgeDetail: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: BadgeCategory
    let isEarned: Bool
    let progress: Double
    let requirement: String
}

enum BadgeCategory: String, CaseIterable {
    case all = "All"
    case recycling = "Recycling"
    case community = "Community"
    case impact = "Impact"
    case maker = "Maker"
}

struct BadgesView_Previews: PreviewProvider {
    static var previews: some View {
        BadgesView()
    }
} 