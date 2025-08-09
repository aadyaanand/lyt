import Foundation
import Firebase
import FirebaseFirestore

@MainActor
class CommunityManager: ObservableObject {
    @Published var availableDonations: [BatteryDonation] = []
    @Published var activeRequests: [BatteryRequest] = []
    @Published var userDonations: [BatteryDonation] = []
    @Published var userRequests: [BatteryRequest] = []
    @Published var matches: [BatteryMatch] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private let authManager = AuthenticationManager()
    
    // MARK: - Donations
    func createDonation(battery: Battery, quantity: Int, location: CLLocationCoordinate2D, notes: String?) async {
        guard let userId = authManager.currentUser?.uid else {
            error = "User not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        let donation = BatteryDonation(
            id: UUID().uuidString,
            userId: userId,
            userName: authManager.currentUser?.displayName ?? "Anonymous",
            battery: battery,
            quantity: quantity,
            location: location,
            notes: notes,
            status: .available,
            createdAt: Date()
        )
        
        do {
            try await saveDonationToFirestore(donation)
            userDonations.append(donation)
            await refreshAvailableDonations()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateDonationStatus(_ donation: BatteryDonation, status: DonationStatus) async {
        isLoading = true
        error = nil
        
        var updatedDonation = donation
        updatedDonation.status = status
        
        do {
            try await updateDonationInFirestore(updatedDonation)
            
            if let index = userDonations.firstIndex(where: { $0.id == donation.id }) {
                userDonations[index] = updatedDonation
            }
            
            await refreshAvailableDonations()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Requests
    func createRequest(batteryType: BatteryType, quantity: Int, location: CLLocationCoordinate2D, urgency: RequestUrgency, notes: String?) async {
        guard let userId = authManager.currentUser?.uid else {
            error = "User not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        let request = BatteryRequest(
            id: UUID().uuidString,
            userId: userId,
            userName: authManager.currentUser?.displayName ?? "Anonymous",
            batteryType: batteryType,
            quantity: quantity,
            location: location,
            urgency: urgency,
            notes: notes,
            status: .active,
            createdAt: Date()
        )
        
        do {
            try await saveRequestToFirestore(request)
            userRequests.append(request)
            await refreshActiveRequests()
            await findMatches(for: request)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateRequestStatus(_ request: BatteryRequest, status: RequestStatus) async {
        isLoading = true
        error = nil
        
        var updatedRequest = request
        updatedRequest.status = status
        
        do {
            try await updateRequestInFirestore(updatedRequest)
            
            if let index = userRequests.firstIndex(where: { $0.id == request.id }) {
                userRequests[index] = updatedRequest
            }
            
            await refreshActiveRequests()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Matchmaking
    func findMatches(for request: BatteryRequest) async {
        let nearbyDonations = availableDonations.filter { donation in
            // Check if donation is compatible
            guard donation.battery.type == request.batteryType,
                  donation.status == .available else { return false }
            
            // Check distance (within 10km)
            let distance = calculateDistance(from: request.location, to: donation.location)
            return distance <= 10.0
        }
        
        for donation in nearbyDonations {
            let match = BatteryMatch(
                id: UUID().uuidString,
                requestId: request.id,
                donationId: donation.id,
                requestUserId: request.userId,
                donationUserId: donation.userId,
                requestUserName: request.userName,
                donationUserName: donation.userName,
                batteryType: request.batteryType,
                quantity: min(request.quantity, donation.quantity),
                distance: calculateDistance(from: request.location, to: donation.location),
                status: .pending,
                createdAt: Date()
            )
            
            matches.append(match)
        }
    }
    
    func acceptMatch(_ match: BatteryMatch) async {
        isLoading = true
        error = nil
        
        var updatedMatch = match
        updatedMatch.status = .accepted
        
        do {
            try await saveMatchToFirestore(updatedMatch)
            
            // Update donation and request status
            if let donation = availableDonations.first(where: { $0.id == match.donationId }) {
                await updateDonationStatus(donation, status: .reserved)
            }
            
            if let request = activeRequests.first(where: { $0.id == match.requestId }) {
                await updateRequestStatus(request, status: .matched)
            }
            
            if let index = matches.firstIndex(where: { $0.id == match.id }) {
                matches[index] = updatedMatch
            }
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func completeMatch(_ match: BatteryMatch) async {
        isLoading = true
        error = nil
        
        var updatedMatch = match
        updatedMatch.status = .completed
        updatedMatch.completedAt = Date()
        
        do {
            try await updateMatchInFirestore(updatedMatch)
            
            // Update donation and request status
            if let donation = availableDonations.first(where: { $0.id == match.donationId }) {
                await updateDonationStatus(donation, status: .completed)
            }
            
            if let request = activeRequests.first(where: { $0.id == match.requestId }) {
                await updateRequestStatus(request, status: .completed)
            }
            
            if let index = matches.firstIndex(where: { $0.id == match.id }) {
                matches[index] = updatedMatch
            }
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Data Refresh
    func refreshAvailableDonations() async {
        do {
            let donations = try await fetchDonationsFromFirestore(status: .available)
            availableDonations = donations
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func refreshActiveRequests() async {
        do {
            let requests = try await fetchRequestsFromFirestore(status: .active)
            activeRequests = requests
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func loadUserData() async {
        guard let userId = authManager.currentUser?.uid else { return }
        
        do {
            let userDonations = try await fetchUserDonationsFromFirestore(userId: userId)
            let userRequests = try await fetchUserRequestsFromFirestore(userId: userId)
            let userMatches = try await fetchUserMatchesFromFirestore(userId: userId)
            
            self.userDonations = userDonations
            self.userRequests = userRequests
            self.matches = userMatches
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Firestore Operations
    private func saveDonationToFirestore(_ donation: BatteryDonation) async throws {
        let data = try donation.toFirestoreData()
        try await db.collection("donations").document(donation.id).setData(data)
    }
    
    private func updateDonationInFirestore(_ donation: BatteryDonation) async throws {
        let data = try donation.toFirestoreData()
        try await db.collection("donations").document(donation.id).updateData(data)
    }
    
    private func saveRequestToFirestore(_ request: BatteryRequest) async throws {
        let data = try request.toFirestoreData()
        try await db.collection("requests").document(request.id).setData(data)
    }
    
    private func updateRequestInFirestore(_ request: BatteryRequest) async throws {
        let data = try request.toFirestoreData()
        try await db.collection("requests").document(request.id).updateData(data)
    }
    
    private func saveMatchToFirestore(_ match: BatteryMatch) async throws {
        let data = try match.toFirestoreData()
        try await db.collection("matches").document(match.id).setData(data)
    }
    
    private func updateMatchInFirestore(_ match: BatteryMatch) async throws {
        let data = try match.toFirestoreData()
        try await db.collection("matches").document(match.id).updateData(data)
    }
    
    private func fetchDonationsFromFirestore(status: DonationStatus) async throws -> [BatteryDonation] {
        let snapshot = try await db.collection("donations")
            .whereField("status", isEqualTo: status.rawValue)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try BatteryDonation.fromFirestoreData(document.data(), id: document.documentID)
        }
    }
    
    private func fetchRequestsFromFirestore(status: RequestStatus) async throws -> [BatteryRequest] {
        let snapshot = try await db.collection("requests")
            .whereField("status", isEqualTo: status.rawValue)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try BatteryRequest.fromFirestoreData(document.data(), id: document.documentID)
        }
    }
    
    private func fetchUserDonationsFromFirestore(userId: String) async throws -> [BatteryDonation] {
        let snapshot = try await db.collection("donations")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try BatteryDonation.fromFirestoreData(document.data(), id: document.documentID)
        }
    }
    
    private func fetchUserRequestsFromFirestore(userId: String) async throws -> [BatteryRequest] {
        let snapshot = try await db.collection("requests")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try BatteryRequest.fromFirestoreData(document.data(), id: document.documentID)
        }
    }
    
    private func fetchUserMatchesFromFirestore(userId: String) async throws -> [BatteryMatch] {
        let snapshot = try await db.collection("matches")
            .whereField("requestUserId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try BatteryMatch.fromFirestoreData(document.data(), id: document.documentID)
        }
    }
    
    // MARK: - Helper Methods
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to km
    }
}

// MARK: - Models
struct BatteryDonation: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let battery: Battery
    let quantity: Int
    let location: CLLocationCoordinate2D
    let notes: String?
    var status: DonationStatus
    let createdAt: Date
    
    enum DonationStatus: String, CaseIterable, Codable {
        case available = "available"
        case reserved = "reserved"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

struct BatteryRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let batteryType: BatteryType
    let quantity: Int
    let location: CLLocationCoordinate2D
    let urgency: RequestUrgency
    let notes: String?
    var status: RequestStatus
    let createdAt: Date
    
    enum RequestStatus: String, CaseIterable, Codable {
        case active = "active"
        case matched = "matched"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    enum RequestUrgency: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
        
        var color: String {
            switch self {
            case .low:
                return "successColor"
            case .medium:
                return "voltLoopYellow"
            case .high:
                return "voltLoopOrange"
            case .urgent:
                return "voltLoopOrange"
            }
        }
    }
}

struct BatteryMatch: Identifiable, Codable {
    let id: String
    let requestId: String
    let donationId: String
    let requestUserId: String
    let donationUserId: String
    let requestUserName: String
    let donationUserName: String
    let batteryType: BatteryType
    let quantity: Int
    let distance: Double
    var status: MatchStatus
    let createdAt: Date
    var completedAt: Date?
    
    enum MatchStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

// MARK: - Firestore Extensions
extension BatteryDonation {
    func toFirestoreData() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
    
    static func fromFirestoreData(_ data: [String: Any], id: String) throws -> BatteryDonation {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(BatteryDonation.self, from: jsonData)
    }
}

extension BatteryRequest {
    func toFirestoreData() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
    
    static func fromFirestoreData(_ data: [String: Any], id: String) throws -> BatteryRequest {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(BatteryRequest.self, from: jsonData)
    }
}

extension BatteryMatch {
    func toFirestoreData() throws -> [String: Any] {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return dict
    }
    
    static func fromFirestoreData(_ data: [String: Any], id: String) throws -> BatteryMatch {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(BatteryMatch.self, from: jsonData)
    }
} 