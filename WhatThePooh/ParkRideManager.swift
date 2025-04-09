import Foundation

class ParkRideManager {
    // Singleton instance
    static let shared = ParkRideManager()
    
    // Dictionary to store park IDs and their corresponding ride arrays
    private var parkRideArray: [String: [String]] = [:]
    
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
            parkRideArray[parkId] = []
        }
        
        isInitialized = true
        
        print("ParkRideManager initialized with \(parkRideArray.count) parks")
    }
    
    // Load rides for a specific park
    func loadRides(_ rides: [String], for parkId: String) {
        // Check if the park exists
        guard parkRideArray.keys.contains(parkId) else {
            print("Cannot load rides: Park with ID \(parkId) does not exist")
            return
        }
        
        // Update the rides for this park
        parkRideArray[parkId] = rides
        
        print("Loaded \(rides.count) rides for park \(parkId)")
    }
    
    // Get all park IDs currently managed by ParkRideManager
    func getAllParkIds() -> [String] {
        return Array(parkRideArray.keys)
    }
    
    // Get all Rides for a specific park
    func getRides(for parkId: String) -> [String] {
        return parkRideArray[parkId] ?? []
    }
    
    // Add a Ride to a specific park
    func addRide(rideName: String, to parkId: String) {
        if var rides = parkRideArray[parkId] {
            rides.append(rideName)
            parkRideArray[parkId] = rides
        }
    }
    
    // Remove a Ride from a specific park
    func removeRide(rideName: String, from parkId: String) {
        if var rides = parkRideArray[parkId] {
            rides.removeAll { $0 == rideName }
            parkRideArray[parkId] = rides
        }
    }
} 
