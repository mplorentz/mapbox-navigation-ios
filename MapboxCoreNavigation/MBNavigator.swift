import Foundation
import MapboxNavigationNative
import CoreLocation

extension MBFixLocation {
    
    convenience init(_ location: CLLocation) {
        self.init(location: location.coordinate,
                  time: location.timestamp,
                  speed: location.speed as NSNumber,
                  bearing: location.course as NSNumber,
                  altitude: location.altitude as NSNumber,
                  accuracyHorizontal: location.horizontalAccuracy as NSNumber,
                  provider: nil)
    }
}

extension MBRouteState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .invalid:
            return "invalid"
        case .initialized:
            return "initialized"
        case .tracking:
            return "tracking"
        case .complete:
            return "complete"
        case .offRoute:
            return "offRoute"
        case .stale:
            return "stale"
        }
    }
}

extension MBNavigationStatus {
    
    var isFirstInstructionOnFirstStep: Bool {
        return stepIndex == 0 && voiceInstruction?.index ?? 0 == 0
    }
}
