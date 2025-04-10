import Foundation

struct SimpleParkRide {
    let parkId: String
    let rideId: String
    let name: String
    let waitTime: Int
    let lastUpdated: Date
    let status: String
}

class ParkRideManager {
    // Singleton instance
    static let shared = ParkRideManager()
    
    // Dictionary to store park IDs and their corresponding ride arrays
//    private var parkRideArray: [String: [String]] = [:]
    
    // New dictionary to store SimpleParkRide objects
    private var parkRides: [String: [SimpleParkRide]] = [:]
    
    // Flag to track if the manager has been initialized
    private var isInitialized = false
    
    // Private initializer to enforce singleton pattern
    private init() { }
    
    // Initialize the ParkRideManager with park IDs
    func initialize(with parkIds: [String]) {
        // Only initialize once
        guard !isInitialized else {
            print("ParkRideManager already initialized")
            return
        }
        
        // Set up the parks with empty ride arrays
        for parkId in parkIds {
//            parkRideArray[parkId] = []
            parkRides[parkId] = []
        }
        
        isInitialized = true
        
        print("ParkRideManager initialized with \(parkRides.count) parks")
        
        // Load rides for all parks
        for parkId in parkIds {
            loadRidesForPark(for: parkId)
        }
    }
    
    private func loadRidesForPark(for parkId: String) {
        NetworkService.shared.performNetworkRequest(id: parkId) { [weak self] data in
            guard let self = self else { return }
            
            guard let data = data else {
                print("No data received for park \(parkId)")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let liveData = json["liveData"] as? [[String: Any]] {
                    
                    let rides = self.parseRides(from: liveData, for: parkId)
                    self.updateRides(rides, for: parkId)
                    
                    print("Loaded \(rides.count) rides for park \(parkId)")
                }
            } catch {
                print("Error parsing ride data for park \(parkId): \(error)")
            }
        }
    }
    
    private func parseRides(from liveData: [[String: Any]], for parkId: String) -> [SimpleParkRide] {
        return liveData.compactMap { rideData -> SimpleParkRide? in
            guard let entityType = rideData["entityType"] as? String,
                  entityType == "ATTRACTION",
                  let id = rideData["id"] as? String,
                  let name = rideData["name"] as? String,
                  let status = rideData["status"] as? String,
                  let lastUpdatedStr = rideData["lastUpdated"] as? String,
                  let lastUpdated = ISO8601DateFormatter().date(from: lastUpdatedStr) else {
                return nil
            }
            
            // Extract wait time from queue->STANDBY->waitTime
            let waitTime = extractWaitTime(from: rideData)
            
            return SimpleParkRide(
                parkId: parkId,
                rideId: id,
                name: name,
                waitTime: waitTime,
                lastUpdated: lastUpdated,
                status: status
            )
        }
    }
    
    private func extractWaitTime(from rideData: [String: Any]) -> Int {
        if let queue = rideData["queue"] as? [String: Any],
           let standby = queue["STANDBY"] as? [String: Any],
           let waitTime = standby["waitTime"] as? Int {
            return waitTime
        }
        return 0
    }
    
    private func updateRides(_ rides: [SimpleParkRide], for parkId: String) {
        // Update both the simple array of IDs and the full ride objects
//        parkRideArray[parkId] = rides.map { $0.rideId }
        parkRides[parkId] = rides
    }
    
    // Get all park IDs currently managed by ParkRideManager
    func getAllParkIds() -> [String] {
        return Array(parkRides.keys)
    }
    
    // Get all Rides for a specific park
    func getRides(for parkId: String) -> [SimpleParkRide] {
        return parkRides[parkId] ?? []
    }
} 
