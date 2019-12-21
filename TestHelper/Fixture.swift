import Foundation
import CoreLocation
import MapboxDirections
@testable import MapboxCoreNavigation

public class Fixture: NSObject {
    public class func stringFromFileNamed(name: String) -> String {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            assert(false, "Fixture \(name) not found.")
            return ""
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            assert(false, "Unable to decode fixture at \(path): \(error).")
            return ""
        }
    }
    
    public class func JSONFromFileNamed(name: String) -> Data {
        guard let path = Bundle(for: Fixture.self).path(forResource: name, ofType: "json") else {
            preconditionFailure("Fixture \(name) not found.")
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            preconditionFailure("No data found at \(path).")
        }
        return data
    }
    
    public class func downloadRouteFixture(coordinates: [CLLocationCoordinate2D], fileName: String, completion: @escaping () -> Void) {
        let accessToken = "<# Mapbox Access Token #>"
        let directions = Directions(accessToken: accessToken)
        
        let options = RouteOptions(coordinates: coordinates, profileIdentifier: .automobileAvoidingTraffic)
        options.includesSteps = true
        options.routeShapeResolution = .full
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        
        _ = directions.calculate(options, completionHandler: { (waypoints, routes, error) in
            guard let _ = routes?.first else { return }
            print("Route downloaded to \(filePath)")
            completion()
        })
    }
    
    public class var blankStyle: URL {
        let path = Bundle(for: self).path(forResource: "EmptyStyle", ofType: "json")
        return URL(fileURLWithPath: path!)
    }
    
    public class func locations(from name: String) -> [CLLocation] {
        guard let path = Bundle(for: Fixture.self).path(forResource: name, ofType: "json") else {
            assert(false, "Fixture \(name) not found.")
            return []
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            assert(false, "No data found at \(path).")
            return []
        }
        
        let locations = try! JSONDecoder().decode([Location].self, from: data)
        
        return locations.map { CLLocation($0) }
    }
    
    public class func route(from jsonFile: String) -> Route {
        let responseData = JSONFromFileNamed(name: jsonFile)
        let response: RouteResponse!
        do {
            response = try JSONDecoder().decode(RouteResponse.self, from: responseData)
        } catch {
            preconditionFailure("Unable to decode JSON fixture: \(error)")
        }
        guard let route = response.routes?.first else {
            preconditionFailure("No routes")
        }
        
        // Like `Directions.postprocess(_:fetchStartDate:uuid:)`
        route.routeIdentifier = response.uuid
        let fetchStartDate = Date(timeIntervalSince1970: 3600)
        route.fetchStartDate = fetchStartDate
        route.responseEndDate = Date(timeInterval: 1, since: fetchStartDate)
        
        return route
    }
    
    public class func waypoints(from jsonFile: String) -> [Waypoint] {
        let responseData = JSONFromFileNamed(name: jsonFile)
        let response: RouteResponse!
        do {
            response = try JSONDecoder().decode(RouteResponse.self, from: responseData)
        } catch {
            preconditionFailure("Unable to decode JSON fixture: \(error)")
        }
        guard let waypoints = response.waypoints else {
            preconditionFailure("No waypoints")
        }
        return waypoints
    }
    
    // Returns `Route` objects from a match response
    public class func routesFromMatches(at filePath: String) -> [Route]? {
        let responseData = JSONFromFileNamed(name: filePath)
        let response: MapMatchingResponse!
        do {
            response = try JSONDecoder().decode(MapMatchingResponse.self, from: responseData)
        } catch {
            preconditionFailure("Unable to decode JSON fixture: \(error)")
        }
        guard let routes = response.routes else {
            preconditionFailure("No routes")
        }
        return routes
    }
    
    public class func generateTrace(for route: Route, speedMultiplier: Double = 1) -> [CLLocation] {
        let traceCollector = TraceCollector()
        let locationManager = SimulatedLocationManager(route: route)
        locationManager.delegate = traceCollector
        locationManager.speedMultiplier = speedMultiplier
        
        while locationManager.currentDistance < route.distance {
            locationManager.tick()
        }
        
        return traceCollector.locations
    }
}

class TraceCollector: NSObject, CLLocationManagerDelegate {
    var locations = [CLLocation]()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }
}
