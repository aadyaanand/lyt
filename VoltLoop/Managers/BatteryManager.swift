import Foundation
import AVFoundation
import Vision
import CoreML

@MainActor
class BatteryManager: ObservableObject {
    @Published var scannedBatteries: [Battery] = []
    @Published var isScanning = false
    @Published var scanError: String?
    @Published var currentBattery: Battery?
    
    private let batteryAPI = BatteryAPI()
    private let cameraManager = CameraManager()
    
    // MARK: - Battery Scanning
    func scanBattery() async {
        isScanning = true
        scanError = nil
        
        do {
            let scannedData = try await cameraManager.scanBarcode()
            let battery = try await batteryAPI.getBatteryInfo(barcode: scannedData)
            
            // Analyze battery health
            let healthStatus = await analyzeBatteryHealth(battery)
            battery.healthStatus = healthStatus
            
            currentBattery = battery
            scannedBatteries.append(battery)
            
            // Save to local storage
            await saveBatteryToStorage(battery)
            
        } catch {
            scanError = error.localizedDescription
        }
        
        isScanning = false
    }
    
    func scanBatteryManually(model: String, type: BatteryType) async {
        isScanning = true
        scanError = nil
        
        do {
            let battery = try await batteryAPI.getBatteryInfo(model: model, type: type)
            let healthStatus = await analyzeBatteryHealth(battery)
            battery.healthStatus = healthStatus
            
            currentBattery = battery
            scannedBatteries.append(battery)
            
            await saveBatteryToStorage(battery)
            
        } catch {
            scanError = error.localizedDescription
        }
        
        isScanning = false
    }
    
    // MARK: - Battery Health Analysis
    private func analyzeBatteryHealth(_ battery: Battery) async -> BatteryHealthStatus {
        // AI-powered health analysis based on battery type, age, and usage patterns
        let healthScore = await calculateHealthScore(battery)
        
        switch healthScore {
        case 0.8...1.0:
            return .reusable
        case 0.4..<0.8:
            return .needsRecharge
        default:
            return .recycleASAP
        }
    }
    
    private func calculateHealthScore(_ battery: Battery) async -> Double {
        // Simulate AI analysis
        // In production, this would use Core ML models trained on battery data
        
        var score = 1.0
        
        // Age factor
        if let age = battery.age {
            let ageInYears = Calendar.current.dateComponents([.year], from: age, to: Date()).year ?? 0
            score -= Double(ageInYears) * 0.1
        }
        
        // Type factor
        switch battery.type {
        case .lithiumIon:
            score *= 0.9 // Lithium-ion batteries degrade faster
        case .alkaline:
            score *= 0.95
        case .rechargeable:
            score *= 0.85
        case .button:
            score *= 0.8
        }
        
        // Usage factor (if available)
        if let cycles = battery.chargeCycles {
            let maxCycles = battery.type.maxCycles
            score *= (1.0 - Double(cycles) / Double(maxCycles))
        }
        
        return max(0.0, min(1.0, score))
    }
    
    // MARK: - Battery Revival
    func reviveBattery(_ battery: Battery) async -> RevivalResult {
        guard battery.healthStatus == .needsRecharge else {
            return .failure("Battery cannot be revived")
        }
        
        // Simulate revival process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let success = Double.random(in: 0...1) > 0.3 // 70% success rate
        
        if success {
            battery.healthStatus = .reusable
            await updateBatteryInStorage(battery)
            return .success("Battery revived successfully!")
        } else {
            return .failure("Revival failed. Battery should be recycled.")
        }
    }
    
    // MARK: - Safety Check
    func checkBatterySafety(_ battery: Battery) -> SafetyResult {
        // Check against recalled batteries database
        let isRecalled = checkRecalledBatteries(battery)
        
        if isRecalled {
            return .unsafe("This battery model has been recalled")
        }
        
        // Check for physical damage indicators
        if battery.hasPhysicalDamage {
            return .unsafe("Physical damage detected")
        }
        
        // Check voltage levels
        if let voltage = battery.voltage {
            switch battery.type {
            case .lithiumIon:
                if voltage < 2.5 || voltage > 4.2 {
                    return .unsafe("Voltage outside safe range")
                }
            case .alkaline:
                if voltage < 0.8 || voltage > 1.6 {
                    return .unsafe("Voltage outside safe range")
                }
            default:
                break
            }
        }
        
        return .safe
    }
    
    private func checkRecalledBatteries(_ battery: Battery) -> Bool {
        // In production, this would check against a database of recalled batteries
        let recalledModels = [
            "DURACELL_AA_2023",
            "ENERGIZER_9V_2022"
        ]
        
        return recalledModels.contains(battery.model)
    }
    
    // MARK: - Storage
    private func saveBatteryToStorage(_ battery: Battery) async {
        // Save to UserDefaults for now, in production use Core Data
        var batteries = UserDefaults.standard.batteries
        batteries.append(battery)
        UserDefaults.standard.batteries = batteries
    }
    
    private func updateBatteryInStorage(_ battery: Battery) async {
        var batteries = UserDefaults.standard.batteries
        if let index = batteries.firstIndex(where: { $0.id == battery.id }) {
            batteries[index] = battery
            UserDefaults.standard.batteries = batteries
        }
    }
    
    func loadBatteriesFromStorage() {
        scannedBatteries = UserDefaults.standard.batteries
    }
}

// MARK: - Battery Models
struct Battery: Identifiable, Codable {
    let id = UUID()
    let model: String
    let type: BatteryType
    let manufacturer: String
    let capacity: Double? // mAh
    let voltage: Double? // V
    let age: Date?
    let chargeCycles: Int?
    var healthStatus: BatteryHealthStatus = .unknown
    var hasPhysicalDamage: Bool = false
    let barcode: String?
    
    init(model: String, type: BatteryType, manufacturer: String, capacity: Double? = nil, voltage: Double? = nil, age: Date? = nil, chargeCycles: Int? = nil, barcode: String? = nil) {
        self.model = model
        self.type = type
        self.manufacturer = manufacturer
        self.capacity = capacity
        self.voltage = voltage
        self.age = age
        self.chargeCycles = chargeCycles
        self.barcode = barcode
    }
}

enum BatteryType: String, CaseIterable, Codable {
    case alkaline = "Alkaline"
    case lithiumIon = "Lithium-Ion"
    case rechargeable = "Rechargeable"
    case button = "Button Cell"
    
    var maxCycles: Int {
        switch self {
        case .alkaline:
            return 0
        case .lithiumIon:
            return 500
        case .rechargeable:
            return 1000
        case .button:
            return 0
        }
    }
    
    var icon: String {
        switch self {
        case .alkaline:
            return "battery.100"
        case .lithiumIon:
            return "battery.100.bolt"
        case .rechargeable:
            return "battery.100.bolt.rtl"
        case .button:
            return "circle.fill"
        }
    }
}

enum BatteryHealthStatus: String, CaseIterable, Codable {
    case reusable = "Reusable"
    case needsRecharge = "Needs Recharge"
    case recycleASAP = "Recycle ASAP"
    case unknown = "Unknown"
    
    var color: String {
        switch self {
        case .reusable:
            return "successColor"
        case .needsRecharge:
            return "voltLoopYellow"
        case .recycleASAP:
            return "voltLoopOrange"
        case .unknown:
            return "secondaryText"
        }
    }
    
    var icon: String {
        switch self {
        case .reusable:
            return "checkmark.circle.fill"
        case .needsRecharge:
            return "exclamationmark.triangle.fill"
        case .recycleASAP:
            return "xmark.circle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

enum RevivalResult {
    case success(String)
    case failure(String)
}

enum SafetyResult {
    case safe
    case unsafe(String)
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    var batteries: [Battery] {
        get {
            guard let data = data(forKey: "scannedBatteries") else { return [] }
            return (try? JSONDecoder().decode([Battery].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            set(data, forKey: "scannedBatteries")
        }
    }
} 