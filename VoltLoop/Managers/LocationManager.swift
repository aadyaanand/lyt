import Foundation
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var nearbyDropOffPoints: [DropOffPoint] = []
    @Published var emergencyRequests: [EmergencyRequest] = []
    @Published var error: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
    }
    
    // MARK: - Location Authorization
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            error = "Location access is required for finding drop-off points and emergency features"
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    // MARK: - Drop-Off Points
    func findNearbyDropOffPoints(radius: Double = 5000) async {
        guard let location = location else {
            error = "Location not available"
            return
        }
        
        do {
            let points = try await fetchDropOffPoints(near: location, radius: radius)
            nearbyDropOffPoints = points
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func fetchDropOffPoints(near location: CLLocation, radius: Double) async throws -> [DropOffPoint] {
        // In production, this would call a real API
        // For now, return mock data
        
        let mockPoints = [
            DropOffPoint(
                id: UUID(),
                name: "Community Recycling Center",
                address: "123 Main St, City, State",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude + 0.001,
                    longitude: location.coordinate.longitude + 0.001
                ),
                type: .recyclingCenter,
                hours: "Mon-Fri 9AM-6PM",
                acceptsTypes: [.alkaline, .lithiumIon, .rechargeable, .button],
                rating: 4.5,
                distance: 0.5
            ),
            DropOffPoint(
                id: UUID(),
                name: "Local Library",
                address: "456 Oak Ave, City, State",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude - 0.002,
                    longitude: location.coordinate.longitude + 0.002
                ),
                type: .library,
                hours: "Mon-Sat 10AM-8PM",
                acceptsTypes: [.alkaline, .button],
                rating: 4.2,
                distance: 1.2
            ),
            DropOffPoint(
                id: UUID(),
                name: "Electronics Store",
                address: "789 Tech Blvd, City, State",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude + 0.003,
                    longitude: location.coordinate.longitude - 0.001
                ),
                type: .electronicsStore,
                hours: "Daily 9AM-9PM",
                acceptsTypes: [.lithiumIon, .rechargeable],
                rating: 4.0,
                distance: 2.1
            ),
            DropOffPoint(
                id: UUID(),
                name: "School Battery Bin",
                address: "321 Education Dr, City, State",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude - 0.001,
                    longitude: location.coordinate.longitude - 0.002
                ),
                type: .school,
                hours: "Mon-Fri 8AM-4PM",
                acceptsTypes: [.alkaline, .button],
                rating: 4.8,
                distance: 0.8
            )
        ]
        
        // Filter by distance and sort
        return mockPoints
            .filter { $0.distance <= radius / 1000 } // Convert to km
            .sorted { $0.distance < $1.distance }
    }
    
    // MARK: - Emergency Features
    func findNearbyEmergencyRequests(radius: Double = 10000) async {
        guard let location = location else {
            error = "Location not available"
            return
        }
        
        do {
            let requests = try await fetchEmergencyRequests(near: location, radius: radius)
            emergencyRequests = requests
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func fetchEmergencyRequests(near location: CLLocation, radius: Double) async throws -> [EmergencyRequest] {
        // Mock emergency requests
        let mockRequests = [
            EmergencyRequest(
                id: UUID(),
                userId: "user1",
                userName: "John Doe",
                type: .powerBank,
                description: "Need power bank for medical device",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude + 0.005,
                    longitude: location.coordinate.longitude + 0.005
                ),
                urgency: .high,
                createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
                isActive: true
            ),
            EmergencyRequest(
                id: UUID(),
                userId: "user2",
                userName: "Jane Smith",
                type: .batteries,
                description: "Need AA batteries for flashlight during outage",
                coordinate: CLLocationCoordinate2D(
                    latitude: location.coordinate.latitude - 0.003,
                    longitude: location.coordinate.longitude + 0.003
                ),
                urgency: .medium,
                createdAt: Date().addingTimeInterval(-1800), // 30 minutes ago
                isActive: true
            )
        ]
        
        return mockRequests
            .filter { $0.isActive }
            .sorted { $0.urgency.rawValue > $1.urgency.rawValue }
    }
    
    // MARK: - Geocoding
    func getAddress(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            
            return [
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea
            ].compactMap { $0 }.joined(separator: ", ")
        } catch {
            return nil
        }
    }
    
    func getCoordinate(for address: String) async -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first else { return nil }
            
            return placemark.location?.coordinate
        } catch {
            return nil
        }
    }
    
    // MARK: - Distance Calculation
    func calculateDistance(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let location = location else { return nil }
        
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: targetLocation) / 1000 // Convert to km
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        location = newLocation
        
        // Update nearby points when location changes significantly
        Task {
            await findNearbyDropOffPoints()
            await findNearbyEmergencyRequests()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error.localizedDescription
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            self.error = "Location access denied"
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Models
struct DropOffPoint: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let type: DropOffType
    let hours: String
    let acceptsTypes: [BatteryType]
    let rating: Double
    let distance: Double // in km
    
    enum DropOffType: String, CaseIterable, Codable {
        case recyclingCenter = "Recycling Center"
        case library = "Library"
        case electronicsStore = "Electronics Store"
        case school = "School"
        case communityCenter = "Community Center"
        case makerspace = "Makerspace"
        
        var icon: String {
            switch self {
            case .recyclingCenter:
                return "leaf.fill"
            case .library:
                return "book.fill"
            case .electronicsStore:
                return "tv.fill"
            case .school:
                return "graduationcap.fill"
            case .communityCenter:
                return "building.2.fill"
            case .makerspace:
                return "wrench.and.screwdriver.fill"
            }
        }
    }
}

struct EmergencyRequest: Identifiable, Codable {
    let id: UUID
    let userId: String
    let userName: String
    let type: EmergencyType
    let description: String
    let coordinate: CLLocationCoordinate2D
    let urgency: UrgencyLevel
    let createdAt: Date
    var isActive: Bool
    
    enum EmergencyType: String, CaseIterable, Codable {
        case powerBank = "Power Bank"
        case batteries = "Batteries"
        case charger = "Charger"
        case device = "Device"
        
        var icon: String {
            switch self {
            case .powerBank:
                return "battery.100.bolt"
            case .batteries:
                return "battery.100"
            case .charger:
                return "bolt.fill"
            case .device:
                return "iphone"
            }
        }
    }
    
    enum UrgencyLevel: Int, CaseIterable, Codable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4
        
        var color: String {
            switch self {
            case .low:
                return "successColor"
            case .medium:
                return "voltLoopYellow"
            case .high:
                return "voltLoopOrange"
            case .critical:
                return "voltLoopOrange"
            }
        }
    }
}

// MARK: - CLLocationCoordinate2D Codable Extension
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
} 