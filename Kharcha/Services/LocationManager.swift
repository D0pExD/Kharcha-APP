import Foundation
import CoreLocation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Real GPS values
    var currentLatitude: Double?
    var currentLongitude: Double?
    var currentLocationName: String?
    
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLoading = false
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func fetchCurrentLocation() {
        isLoading = true
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            isLoading = false
        }
    }
    
    // Asynchronous one-shot location fetcher for Intents and background tasks
    func fetchLocationAsync() async -> (lat: Double?, lng: Double?, name: String?) {
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            return (nil, nil, nil)
        }
        
        let loc = manager.location
        guard let location = loc else {
            return (nil, nil, nil)
        }
        
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        var name: String? = nil
        if let placemark = placemarks?.first {
            let components = [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea
            ].compactMap { $0 }
            name = components.prefix(2).joined(separator: ", ")
        }
        
        return (lat, lng, name)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }
        
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false
                
                if let placemark = placemarks?.first {
                    let components = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea
                    ].compactMap { $0 }
                    
                    self.currentLocationName = components.prefix(2).joined(separator: ", ")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
    
    func clearLocation() {
        currentLatitude = nil
        currentLongitude = nil
        currentLocationName = nil
    }
}
