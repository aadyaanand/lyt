import SwiftUI
import AVFoundation

struct BatteryToolsView: View {
    @EnvironmentObject var batteryManager: BatteryManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedTab = 0
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @State private var showingReviveMode = false
    @State private var showingSafetyGuide = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Scan",
                            icon: "camera.fill",
                            isSelected: selectedTab == 0
                        ) {
                            selectedTab = 0
                        }
                        
                        TabButton(
                            title: "Revive",
                            icon: "bolt.fill",
                            isSelected: selectedTab == 1
                        ) {
                            selectedTab = 1
                        }
                        
                        TabButton(
                            title: "Safety",
                            icon: "shield.fill",
                            isSelected: selectedTab == 2
                        ) {
                            selectedTab = 2
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        ScanBatteryView(
                            showingScanner: $showingScanner,
                            showingManualEntry: $showingManualEntry
                        )
                        .tag(0)
                        
                        ReviveModeView(showingReviveMode: $showingReviveMode)
                            .tag(1)
                        
                        SafetyGuideView(showingSafetyGuide: $showingSafetyGuide)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Battery Tools")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingScanner) {
            BatteryScannerView()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBatteryEntryView()
        }
        .sheet(isPresented: $showingReviveMode) {
            ReviveModeDetailView()
        }
        .sheet(isPresented: $showingSafetyGuide) {
            SafetyGuideDetailView()
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .voltLoopBlue : .secondaryText)
                    .voltLoopGlow(color: isSelected ? .voltLoopBlue : .clear)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(isSelected ? .voltLoopBlue : .secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.voltLoopBlue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.voltLoopBlue : Color.secondaryBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScanBatteryView: View {
    @Binding var showingScanner: Bool
    @Binding var showingManualEntry: Bool
    @EnvironmentObject var batteryManager: BatteryManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Battery Display
                if let currentBattery = batteryManager.currentBattery {
                    BatteryResultCard(battery: currentBattery)
                }
                
                // Scan Options
                VStack(spacing: 16) {
                    Text("Scan Battery")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Scan a barcode or manually enter battery information")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showingScanner = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                Text("Scan Barcode")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .voltLoopButtonStyle()
                        
                        Button(action: {
                            showingManualEntry = true
                        }) {
                            HStack {
                                Image(systemName: "keyboard")
                                    .font(.system(size: 20))
                                Text("Manual Entry")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .voltLoopButtonStyle(isPrimary: false)
                    }
                }
                .padding(.horizontal, 20)
                
                // Recent Scans
                if !batteryManager.scannedBatteries.isEmpty {
                    VStack(spacing: 16) {
                        Text("Recent Scans")
                            .font(.system(size: 20, weight: .bold, design: .default))
                            .foregroundColor(.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(batteryManager.scannedBatteries.prefix(5)) { battery in
                                RecentBatteryCard(battery: battery)
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

struct BatteryResultCard: View {
    let battery: Battery
    @EnvironmentObject var batteryManager: BatteryManager
    @State private var showingSafetyCheck = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Battery Info
            HStack {
                Image(systemName: battery.type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.voltLoopBlue)
                    .voltLoopGlow(color: .voltLoopBlue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(battery.model)
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text(battery.manufacturer)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(battery.type.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                    
                    if let capacity = battery.capacity {
                        Text("\(Int(capacity)) mAh")
                            .font(.system(size: 12, weight: .medium, design: .default))
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            
            // Health Status
            HStack {
                Image(systemName: battery.healthStatus.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(battery.healthStatus.color))
                
                Text(battery.healthStatus.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(Color(battery.healthStatus.color))
                
                Spacer()
                
                Button("Safety Check") {
                    showingSafetyCheck = true
                }
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.voltLoopBlue)
            }
            
            // Action Buttons
            if battery.healthStatus == .needsRecharge {
                Button("Try to Revive") {
                    // Navigate to revive mode
                }
                .voltLoopButtonStyle()
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryBorder.opacity(0.3), lineWidth: 1)
        )
        .voltLoopGlow()
        .padding(.horizontal, 20)
        .alert("Safety Check", isPresented: $showingSafetyCheck) {
            Button("OK") { }
        } message: {
            let safetyResult = batteryManager.checkBatterySafety(battery)
            switch safetyResult {
            case .safe:
                Text("This battery appears to be safe to use.")
            case .unsafe(let reason):
                Text("Safety concern: \(reason)")
            }
        }
    }
}

struct RecentBatteryCard: View {
    let battery: Battery
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: battery.type.icon)
                .font(.system(size: 20))
                .foregroundColor(.voltLoopBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(battery.model)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.primaryText)
                
                Text(battery.healthStatus.rawValue)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(Color(battery.healthStatus.color))
            }
            
            Spacer()
            
            Text(battery.type.rawValue)
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

struct ReviveModeView: View {
    @Binding var showingReviveMode: Bool
    @EnvironmentObject var batteryManager: BatteryManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopYellow)
                        .voltLoopGlow(color: .voltLoopYellow, radius: 20)
                    
                    Text("Revive Mode")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Give your batteries a second life with our revival techniques")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Revival Steps
                VStack(spacing: 16) {
                    Text("Revival Steps")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        RevivalStepCard(
                            step: 1,
                            title: "Check Battery Type",
                            description: "Ensure the battery is rechargeable and not damaged",
                            icon: "checkmark.shield.fill"
                        )
                        
                        RevivalStepCard(
                            step: 2,
                            title: "Clean Contacts",
                            description: "Remove corrosion and clean battery terminals",
                            icon: "sparkles"
                        )
                        
                        RevivalStepCard(
                            step: 3,
                            title: "Slow Charge",
                            description: "Use a slow charger at low current for 24 hours",
                            icon: "battery.100.bolt"
                        )
                        
                        RevivalStepCard(
                            step: 4,
                            title: "Test Performance",
                            description: "Check voltage and capacity after revival",
                            icon: "gauge"
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Start Revival Button
                Button(action: {
                    showingReviveMode = true
                }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                        Text("Start Revival Process")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .voltLoopButtonStyle()
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

struct RevivalStepCard: View {
    let step: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.voltLoopBlue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(step)")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.voltLoopBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.voltLoopYellow)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.primaryText)
                }
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
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

struct SafetyGuideView: View {
    @Binding var showingSafetyGuide: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.voltLoopOrange)
                        .voltLoopGlow(color: .voltLoopOrange, radius: 20)
                    
                    Text("Battery Safety")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                    
                    Text("Learn how to handle batteries safely and identify potential hazards")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                
                // Safety Guidelines
                VStack(spacing: 16) {
                    Text("Safety Guidelines")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        SafetyGuidelineCard(
                            title: "Safe Batteries",
                            description: "Check for proper labeling, no damage, and correct voltage",
                            icon: "checkmark.circle.fill",
                            color: .successColor
                        )
                        
                        SafetyGuidelineCard(
                            title: "Unsafe Batteries",
                            description: "Avoid swollen, leaking, or damaged batteries",
                            icon: "xmark.circle.fill",
                            color: .voltLoopOrange
                        )
                        
                        SafetyGuidelineCard(
                            title: "Storage",
                            description: "Store in cool, dry place away from metal objects",
                            icon: "archivebox.fill",
                            color: .voltLoopBlue
                        )
                        
                        SafetyGuidelineCard(
                            title: "Disposal",
                            description: "Never throw batteries in regular trash",
                            icon: "trash.fill",
                            color: .voltLoopOrange
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // View Full Guide Button
                Button(action: {
                    showingSafetyGuide = true
                }) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                        Text("View Full Safety Guide")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .voltLoopButtonStyle()
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
}

struct SafetyGuidelineCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
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

struct BatteryToolsView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryToolsView()
            .environmentObject(BatteryManager())
            .environmentObject(LocationManager())
    }
} 