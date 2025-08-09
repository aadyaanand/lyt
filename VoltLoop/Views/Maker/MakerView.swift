import SwiftUI

struct MakerView: View {
    @State private var selectedTab = 0
    @State private var showingProjectDetail = false
    @State private var showingTeacherPortal = false
    @State private var selectedProject: Project?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Tech Library",
                            icon: "book.fill",
                            isSelected: selectedTab == 0
                        ) {
                            selectedTab = 0
                        }
                        
                        TabButton(
                            title: "Teacher Portal",
                            icon: "graduationcap.fill",
                            isSelected: selectedTab == 1
                        ) {
                            selectedTab = 1
                        }
                        
                        TabButton(
                            title: "Projects",
                            icon: "wrench.and.screwdriver.fill",
                            isSelected: selectedTab == 2
                        ) {
                            selectedTab = 2
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        TechLibraryView(
                            showingProjectDetail: $showingProjectDetail,
                            selectedProject: $selectedProject
                        )
                        .tag(0)
                        
                        TeacherPortalView(showingTeacherPortal: $showingTeacherPortal)
                            .tag(1)
                        
                        CommunityProjectsView(
                            showingProjectDetail: $showingProjectDetail,
                            selectedProject: $selectedProject
                        )
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Maker")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingProjectDetail) {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            }
        }
        .sheet(isPresented: $showingTeacherPortal) {
            TeacherPortalDetailView()
        }
    }
}

struct TechLibraryView: View {
    @Binding var showingProjectDetail: Bool
    @Binding var selectedProject: Project?
    @State private var selectedFilter: ProjectFilter = .all
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopBlue)
                        .voltLoopGlow(color: .voltLoopBlue, radius: 20)
                    
                    Text("Tech Library")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Discover projects using repurposed batteries")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Search and Filters
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondaryText)
                        
                        TextField("Search projects...", text: $searchText)
                            .foregroundColor(.primaryText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondaryBorder, lineWidth: 1)
                    )
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ProjectFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20)
                
                // Projects Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(getFilteredProjects()) { project in
                        ProjectCard(project: project) {
                            selectedProject = project
                            showingProjectDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
    
    private func getFilteredProjects() -> [Project] {
        var projects = getMockProjects()
        
        // Apply search filter
        if !searchText.isEmpty {
            projects = projects.filter { project in
                project.title.localizedCaseInsensitiveContains(searchText) ||
                project.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply category filter
        if selectedFilter != .all {
            projects = projects.filter { $0.category == selectedFilter }
        }
        
        return projects
    }
    
    private func getMockProjects() -> [Project] {
        return [
            Project(
                id: "1",
                title: "Solar Light",
                description: "Create a solar-powered light using old batteries",
                category: .electronics,
                difficulty: .beginner,
                batteryTypes: [.alkaline, .rechargeable],
                imageName: "lightbulb.fill",
                materials: ["Old batteries", "LED", "Solar panel", "Wires"],
                instructions: "Step-by-step instructions for building a solar light...",
                estimatedTime: "2 hours",
                ageGroup: "12+"
            ),
            Project(
                id: "2",
                title: "Robot Car",
                description: "Build a simple robot car with recycled batteries",
                category: .robotics,
                difficulty: .intermediate,
                batteryTypes: [.lithiumIon, .rechargeable],
                imageName: "car.fill",
                materials: ["Old batteries", "DC motors", "Wheels", "Chassis"],
                instructions: "Detailed guide for building a robot car...",
                estimatedTime: "4 hours",
                ageGroup: "14+"
            ),
            Project(
                id: "3",
                title: "Wind Turbine",
                description: "Generate electricity with a homemade wind turbine",
                category: .renewable,
                difficulty: .advanced,
                batteryTypes: [.rechargeable],
                imageName: "wind",
                materials: ["Old batteries", "Generator", "Blades", "Tower"],
                instructions: "Advanced project for wind energy generation...",
                estimatedTime: "8 hours",
                ageGroup: "16+"
            ),
            Project(
                id: "4",
                title: "Phone Charger",
                description: "DIY phone charger using repurposed batteries",
                category: .electronics,
                difficulty: .beginner,
                batteryTypes: [.lithiumIon],
                imageName: "iphone",
                materials: ["Old batteries", "USB connector", "Voltage regulator"],
                instructions: "Simple phone charger project...",
                estimatedTime: "1 hour",
                ageGroup: "10+"
            )
        ]
    }
}

struct TeacherPortalView: View {
    @Binding var showingTeacherPortal: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopYellow)
                        .voltLoopGlow(color: .voltLoopYellow, radius: 20)
                    
                    Text("Teacher Portal")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Request supplies and track donations for your classroom")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Quick Actions
                VStack(spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        QuickActionButton(
                            title: "Request Supplies",
                            subtitle: "Request batteries and materials for your class",
                            icon: "plus.circle.fill",
                            color: .voltLoopBlue
                        ) {
                            showingTeacherPortal = true
                        }
                        
                        QuickActionButton(
                            title: "Track Donations",
                            subtitle: "View and manage incoming donations",
                            icon: "chart.bar.fill",
                            color: .successColor
                        ) {
                            // Navigate to donations tracking
                        }
                        
                        QuickActionButton(
                            title: "Class Projects",
                            subtitle: "Browse projects suitable for your students",
                            icon: "book.fill",
                            color: .voltLoopYellow
                        ) {
                            // Navigate to class projects
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Recent Requests
                VStack(spacing: 16) {
                    Text("Recent Requests")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        RequestCard(
                            title: "Science Class - Grade 8",
                            description: "Need 50 AA batteries for electricity experiments",
                            status: "Pending",
                            date: "2 days ago"
                        )
                        
                        RequestCard(
                            title: "Robotics Club",
                            description: "Requesting lithium-ion batteries for robot building",
                            status: "Fulfilled",
                            date: "1 week ago"
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

struct CommunityProjectsView: View {
    @Binding var showingProjectDetail: Bool
    @Binding var selectedProject: Project?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopOrange)
                        .voltLoopGlow(color: .voltLoopOrange, radius: 20)
                    
                    Text("Community Projects")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Collaborative projects from the VoltLoop community")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Featured Project
                VStack(spacing: 16) {
                    Text("Featured Project")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    FeaturedProjectCard(
                        project: Project(
                            id: "featured",
                            title: "Community Solar Array",
                            description: "Large-scale solar installation using recycled batteries",
                            category: .renewable,
                            difficulty: .advanced,
                            batteryTypes: [.lithiumIon, .rechargeable],
                            imageName: "sun.max.fill",
                            materials: ["100+ old batteries", "Solar panels", "Inverter"],
                            instructions: "Community-wide solar project...",
                            estimatedTime: "40 hours",
                            ageGroup: "18+"
                        )
                    ) {
                        selectedProject = Project(
                            id: "featured",
                            title: "Community Solar Array",
                            description: "Large-scale solar installation using recycled batteries",
                            category: .renewable,
                            difficulty: .advanced,
                            batteryTypes: [.lithiumIon, .rechargeable],
                            imageName: "sun.max.fill",
                            materials: ["100+ old batteries", "Solar panels", "Inverter"],
                            instructions: "Community-wide solar project...",
                            estimatedTime: "40 hours",
                            ageGroup: "18+"
                        )
                        showingProjectDetail = true
                    }
                }
                .padding(.horizontal, 20)
                
                // Community Stats
                VStack(spacing: 16) {
                    Text("Community Stats")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Projects Created",
                            value: "156",
                            icon: "wrench.and.screwdriver.fill",
                            color: .voltLoopBlue
                        )
                        
                        StatCard(
                            title: "Batteries Used",
                            value: "2,847",
                            icon: "battery.100",
                            color: .voltLoopOrange
                        )
                        
                        StatCard(
                            title: "Active Makers",
                            value: "89",
                            icon: "person.3.fill",
                            color: .successColor
                        )
                        
                        StatCard(
                            title: "Schools Involved",
                            value: "23",
                            icon: "building.2.fill",
                            color: .voltLoopYellow
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

// MARK: - Supporting Views
struct FilterChip: View {
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

struct ProjectCard: View {
    let project: Project
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: project.imageName)
                    .font(.system(size: 32))
                    .foregroundColor(.voltLoopBlue)
                    .voltLoopGlow(color: .voltLoopBlue)
                
                VStack(spacing: 4) {
                    Text(project.title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(project.description)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                HStack {
                    Text(project.difficulty.rawValue)
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundColor(.voltLoopBlue)
                    
                    Spacer()
                    
                    Text(project.estimatedTime)
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondaryBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeaturedProjectCard: View {
    let project: Project
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: project.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(.voltLoopOrange)
                        .voltLoopGlow(color: .voltLoopOrange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.title)
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                        
                        Text(project.description)
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Text(project.difficulty.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.voltLoopOrange)
                    
                    Spacer()
                    
                    Text(project.estimatedTime)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.voltLoopOrange.opacity(0.3), lineWidth: 1)
            )
            .voltLoopGlow(color: .voltLoopOrange)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct RequestCard: View {
    let title: String
    let description: String
    let status: String
    let date: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(status)
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .foregroundColor(status == "Fulfilled" ? .successColor : .voltLoopOrange)
                    
                    Text(date)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
            }
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .voltLoopGlow(color: color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondaryBorder, lineWidth: 1)
        )
    }
}

// MARK: - Models
struct Project: Identifiable {
    let id: String
    let title: String
    let description: String
    let category: ProjectFilter
    let difficulty: Difficulty
    let batteryTypes: [BatteryType]
    let imageName: String
    let materials: [String]
    let instructions: String
    let estimatedTime: String
    let ageGroup: String
}

enum ProjectFilter: String, CaseIterable {
    case all = "All"
    case electronics = "Electronics"
    case robotics = "Robotics"
    case renewable = "Renewable Energy"
    case art = "Art & Crafts"
}

enum Difficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

struct MakerView_Previews: PreviewProvider {
    static var previews: some View {
        MakerView()
    }
} 