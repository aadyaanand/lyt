import SwiftUI
import MapKit

struct CommunityView: View {
    @EnvironmentObject var communityManager: CommunityManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0
    @State private var showingDonationForm = false
    @State private var showingRequestForm = false
    @State private var showingEmergencyMap = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Swap",
                            icon: "arrow.triangle.2.circlepath",
                            isSelected: selectedTab == 0
                        ) {
                            selectedTab = 0
                        }
                        
                        TabButton(
                            title: "Emergency",
                            icon: "exclamationmark.triangle.fill",
                            isSelected: selectedTab == 1
                        ) {
                            selectedTab = 1
                        }
                        
                        TabButton(
                            title: "Power Packs",
                            icon: "cube.box.fill",
                            isSelected: selectedTab == 2
                        ) {
                            selectedTab = 2
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        BatterySwapView(
                            showingDonationForm: $showingDonationForm,
                            showingRequestForm: $showingRequestForm
                        )
                        .tag(0)
                        
                        EmergencyView(showingEmergencyMap: $showingEmergencyMap)
                            .tag(1)
                        
                        PowerPacksView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingDonationForm) {
            DonationFormView()
        }
        .sheet(isPresented: $showingRequestForm) {
            RequestFormView()
        }
        .sheet(isPresented: $showingEmergencyMap) {
            EmergencyMapView()
        }
        .task {
            await communityManager.refreshAvailableDonations()
            await communityManager.refreshActiveRequests()
            await locationManager.findNearbyEmergencyRequests()
        }
    }
}

struct BatterySwapView: View {
    @Binding var showingDonationForm: Bool
    @Binding var showingRequestForm: Bool
    @EnvironmentObject var communityManager: CommunityManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopBlue)
                        .voltLoopGlow(color: .voltLoopBlue, radius: 20)
                    
                    Text("Battery Swap Network")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Share and find batteries in your community")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingDonationForm = true
                    }) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 20))
                            Text("Donate Batteries")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .voltLoopButtonStyle()
                    
                    Button(action: {
                        showingRequestForm = true
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 20))
                            Text("Request Batteries")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .voltLoopButtonStyle(isPrimary: false)
                }
                .padding(.horizontal, 20)
                
                // Available Donations
                if !communityManager.availableDonations.isEmpty {
                    VStack(spacing: 16) {
                        Text("Available Donations")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(communityManager.availableDonations.prefix(5)) { donation in
                                DonationCard(donation: donation)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Active Requests
                if !communityManager.activeRequests.isEmpty {
                    VStack(spacing: 16) {
                        Text("Active Requests")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(communityManager.activeRequests.prefix(5)) { request in
                                RequestCard(request: request)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Your Activity
                if !communityManager.userDonations.isEmpty || !communityManager.userRequests.isEmpty {
                    VStack(spacing: 16) {
                        Text("Your Activity")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ForEach(communityManager.userDonations.prefix(3)) { donation in
                                UserActivityCard(
                                    title: "Donation: \(donation.battery.model)",
                                    subtitle: "\(donation.quantity) batteries",
                                    status: donation.status.rawValue.capitalized,
                                    date: donation.createdAt
                                )
                            }
                            
                            ForEach(communityManager.userRequests.prefix(3)) { request in
                                UserActivityCard(
                                    title: "Request: \(request.batteryType.rawValue)",
                                    subtitle: "\(request.quantity) batteries needed",
                                    status: request.status.rawValue.capitalized,
                                    date: request.createdAt
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
}

struct DonationCard: View {
    let donation: BatteryDonation
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: donation.battery.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.voltLoopBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(donation.battery.model)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("by \(donation.userName)")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(donation.quantity)")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.voltLoopBlue)
                    
                    Text("available")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
            }
            
            if let notes = donation.notes {
                Text(notes)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Text(donation.battery.type.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text(donation.createdAt, style: .relative)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
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

struct RequestCard: View {
    let request: BatteryRequest
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: request.batteryType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.voltLoopOrange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(request.batteryType.rawValue) needed")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("by \(request.userName)")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(request.quantity)")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.voltLoopOrange)
                    
                    Text("needed")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
            }
            
            if let notes = request.notes {
                Text(notes)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Text(request.urgency.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(Color(request.urgency.color))
                
                Spacer()
                
                Text(request.createdAt, style: .relative)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
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

struct UserActivityCard: View {
    let title: String
    let subtitle: String
    let status: String
    let date: Date
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(status)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.voltLoopBlue)
                
                Text(date, style: .relative)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
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

struct EmergencyView: View {
    @Binding var showingEmergencyMap: Bool
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopOrange)
                        .voltLoopGlow(color: .voltLoopOrange, radius: 20)
                    
                    Text("Emergency Mode")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Find and provide emergency power assistance")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Emergency Map Button
                Button(action: {
                    showingEmergencyMap = true
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.system(size: 20))
                        Text("View Emergency Map")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .voltLoopButtonStyle()
                .padding(.horizontal, 20)
                
                // Emergency Requests
                if !locationManager.emergencyRequests.isEmpty {
                    VStack(spacing: 16) {
                        Text("Nearby Emergency Requests")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(locationManager.emergencyRequests) { request in
                                EmergencyRequestCard(request: request)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.successColor)
                        
                        Text("No Emergency Requests")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.primaryText)
                        
                        Text("Great! There are no active emergency requests in your area.")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)
        }
    }
}

struct EmergencyRequestCard: View {
    let request: EmergencyRequest
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: request.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.voltLoopOrange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.type.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("by \(request.userName)")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(request.urgency.rawValue.capitalized)
                        .font(.system(size: 14, weight: .bold, design: .default))
                        .foregroundColor(Color(request.urgency.color))
                    
                    Text("\(String(format: "%.1f", request.distance)) km")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
            }
            
            Text(request.description)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text(request.createdAt, style: .relative)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Button("Respond") {
                    // Handle response
                }
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(.voltLoopBlue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.voltLoopOrange.opacity(0.3), lineWidth: 1)
        )
        .voltLoopGlow(color: .voltLoopOrange, radius: 5)
    }
}

struct PowerPacksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopYellow)
                        .voltLoopGlow(color: .voltLoopYellow, radius: 20)
                    
                    Text("Power Packs")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Pre-packed battery bundles for community needs")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Power Pack Types
                VStack(spacing: 16) {
                    Text("Available Packs")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    LazyVStack(spacing: 12) {
                        PowerPackCard(
                            title: "Emergency Pack",
                            description: "4 AA, 2 AAA, 1 9V battery",
                            icon: "exclamationmark.triangle.fill",
                            color: .voltLoopOrange,
                            quantity: 5
                        )
                        
                        PowerPackCard(
                            title: "Student Pack",
                            description: "8 AA, 4 AAA batteries",
                            icon: "graduationcap.fill",
                            color: .voltLoopBlue,
                            quantity: 12
                        )
                        
                        PowerPackCard(
                            title: "Maker Pack",
                            description: "Mixed battery types for projects",
                            icon: "wrench.and.screwdriver.fill",
                            color: .voltLoopYellow,
                            quantity: 8
                        )
                        
                        PowerPackCard(
                            title: "Shelter Pack",
                            description: "Large quantity for community centers",
                            icon: "building.2.fill",
                            color: .successColor,
                            quantity: 25
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

struct PowerPackCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let quantity: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 40)
            
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
                Text("\(quantity)")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(color)
                
                Text("available")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
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

struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        CommunityView()
            .environmentObject(CommunityManager())
            .environmentObject(LocationManager())
    }
} 