import Foundation

class NetworkService {
    // Singleton instance
    static let shared = NetworkService()
    
    // Private initializer to enforce singleton pattern
    private init() { }
    
    // Perform a network request for a specific entity ID
    func performNetworkRequest(id: String, completion: @escaping (Data?) -> Void) {
        let urlString = "https://api.themeparks.wiki/v1/entity/\(id)/live"
        guard let url = URL(string: urlString) else {
            print("\(ISO8601DateFormatter().string(from: Date())) - Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("\(ISO8601DateFormatter().string(from: Date())) - Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("\(ISO8601DateFormatter().string(from: Date())) - Invalid response type")
                completion(nil)
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                print("\(ISO8601DateFormatter().string(from: Date())) - HTTP error: \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("\(ISO8601DateFormatter().string(from: Date())) - No data received")
                completion(nil)
                return
            }
            
            completion(data)
        }
        
        task.resume()
    }
} 