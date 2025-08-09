import Foundation

class BatteryAPI {
    private let baseURL = "https://api.batteryapi.com/v1"
    private let apiKey = "YOUR_API_KEY" // In production, use environment variables
    
    // MARK: - Battery Information
    func getBatteryInfo(barcode: String) async throws -> Battery {
        let url = URL(string: "\(baseURL)/battery/barcode/\(barcode)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BatteryAPIError.invalidResponse
        }
        
        let batteryResponse = try JSONDecoder().decode(BatteryAPIResponse.self, from: data)
        return batteryResponse.toBattery()
    }
    
    func getBatteryInfo(model: String, type: BatteryType) async throws -> Battery {
        let url = URL(string: "\(baseURL)/battery/search")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let searchData = BatterySearchRequest(model: model, type: type.rawValue)
        request.httpBody = try JSONEncoder().encode(searchData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BatteryAPIError.invalidResponse
        }
        
        let batteryResponse = try JSONDecoder().decode(BatteryAPIResponse.self, from: data)
        return batteryResponse.toBattery()
    }
    
    // MARK: - Battery Database
    func getBatteryDatabase() async throws -> [Battery] {
        let url = URL(string: "\(baseURL)/battery/database")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BatteryAPIError.invalidResponse
        }
        
        let databaseResponse = try JSONDecoder().decode(BatteryDatabaseResponse.self, from: data)
        return databaseResponse.batteries.map { $0.toBattery() }
    }
    
    // MARK: - Recalled Batteries
    func getRecalledBatteries() async throws -> [String] {
        let url = URL(string: "\(baseURL)/battery/recalls")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BatteryAPIError.invalidResponse
        }
        
        let recallResponse = try JSONDecoder().decode(RecallResponse.self, from: data)
        return recallResponse.recalledModels
    }
    
    // MARK: - Environmental Impact
    func getEnvironmentalImpact(batteryType: BatteryType, quantity: Int) async throws -> EnvironmentalImpact {
        let url = URL(string: "\(baseURL)/impact/calculate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let impactData = ImpactRequest(type: batteryType.rawValue, quantity: quantity)
        request.httpBody = try JSONEncoder().encode(impactData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BatteryAPIError.invalidResponse
        }
        
        return try JSONDecoder().decode(EnvironmentalImpact.self, from: data)
    }
}

// MARK: - API Models
struct BatteryAPIResponse: Codable {
    let model: String
    let type: String
    let manufacturer: String
    let capacity: Double?
    let voltage: Double?
    let age: String?
    let chargeCycles: Int?
    let barcode: String?
    
    func toBattery() -> Battery {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return Battery(
            model: model,
            type: BatteryType(rawValue: type) ?? .alkaline,
            manufacturer: manufacturer,
            capacity: capacity,
            voltage: voltage,
            age: age != nil ? dateFormatter.date(from: age!) : nil,
            chargeCycles: chargeCycles,
            barcode: barcode
        )
    }
}

struct BatterySearchRequest: Codable {
    let model: String
    let type: String
}

struct BatteryDatabaseResponse: Codable {
    let batteries: [BatteryAPIResponse]
}

struct RecallResponse: Codable {
    let recalledModels: [String]
}

struct ImpactRequest: Codable {
    let type: String
    let quantity: Int
}

struct EnvironmentalImpact: Codable {
    let co2Avoided: Double // kg
    let rareMetalsPreserved: Double // grams
    let eWasteDiverted: Double // kg
    let waterSaved: Double // liters
}

// MARK: - Mock Data for Development
extension BatteryAPI {
    func getMockBatteryInfo(barcode: String) async throws -> Battery {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Return mock data based on barcode
        let mockBatteries: [String: Battery] = [
            "123456789": Battery(
                model: "DURACELL_AA",
                type: .alkaline,
                manufacturer: "Duracell",
                capacity: 2500,
                voltage: 1.5,
                age: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
                chargeCycles: nil,
                barcode: "123456789"
            ),
            "987654321": Battery(
                model: "ENERGIZER_LITHIUM",
                type: .lithiumIon,
                manufacturer: "Energizer",
                capacity: 3000,
                voltage: 3.7,
                age: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
                chargeCycles: 150,
                barcode: "987654321"
            )
        ]
        
        return mockBatteries[barcode] ?? Battery(
            model: "UNKNOWN_\(barcode.prefix(3))",
            type: .alkaline,
            manufacturer: "Unknown",
            capacity: 2000,
            voltage: 1.5,
            age: nil,
            chargeCycles: nil,
            barcode: barcode
        )
    }
    
    func getMockEnvironmentalImpact(batteryType: BatteryType, quantity: Int) async throws -> EnvironmentalImpact {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let baseImpact: EnvironmentalImpact
        switch batteryType {
        case .lithiumIon:
            baseImpact = EnvironmentalImpact(
                co2Avoided: 0.5,
                rareMetalsPreserved: 2.0,
                eWasteDiverted: 0.1,
                waterSaved: 50
            )
        case .alkaline:
            baseImpact = EnvironmentalImpact(
                co2Avoided: 0.3,
                rareMetalsPreserved: 0.5,
                eWasteDiverted: 0.05,
                waterSaved: 30
            )
        case .rechargeable:
            baseImpact = EnvironmentalImpact(
                co2Avoided: 0.8,
                rareMetalsPreserved: 3.0,
                eWasteDiverted: 0.15,
                waterSaved: 80
            )
        case .button:
            baseImpact = EnvironmentalImpact(
                co2Avoided: 0.1,
                rareMetalsPreserved: 0.2,
                eWasteDiverted: 0.02,
                waterSaved: 10
            )
        }
        
        return EnvironmentalImpact(
            co2Avoided: baseImpact.co2Avoided * Double(quantity),
            rareMetalsPreserved: baseImpact.rareMetalsPreserved * Double(quantity),
            eWasteDiverted: baseImpact.eWasteDiverted * Double(quantity),
            waterSaved: baseImpact.waterSaved * Double(quantity)
        )
    }
}

// MARK: - Errors
enum BatteryAPIError: Error, LocalizedError {
    case invalidResponse
    case networkError
    case decodingError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network connection error"
        case .decodingError:
            return "Failed to decode response"
        case .apiError(let message):
            return message
        }
    }
} 