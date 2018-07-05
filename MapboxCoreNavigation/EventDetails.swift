import Foundation
import CoreLocation
import Polyline
import UIKit
import AVFoundation
import MapboxDirections

struct EventDetails: Encodable {
    
    let originalRequestIdentifier: String?
    let requestIdentifier: String?
    let coordinate: CLLocationCoordinate2D?
    let originalGeometry: Polyline?
    let originalDistance: CLLocationDistance?
    let originalEstimatedDuration: TimeInterval?
    let originalStepCount: Int?
    let geometry: Polyline?
    let distance: CLLocationDistance?
    let estimatedDuration: TimeInterval?
    let created: Date = Date()
    let startTimestamp: Date?
    let sdkIdentifier: String
    let sdkVersion: String = String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!)
    let profile: String
    let simulation: Bool
    let sessionIdentifier: String
    let distanceCompleted: CLLocationDistance
    let distanceRemaining: TimeInterval
    let durationRemaining: TimeInterval
    let rerouteCount: Int
    let volumeLevel: Int = Int(AVAudioSession.sharedInstance().outputVolume * 100)
    let audioType: String = AVAudioSession.sharedInstance().audioType
    let screenBrightness: Int = Int(UIScreen.main.brightness * 100)
    let batteryPluggedIn: Bool = [.charging, .full].contains(UIDevice.current.batteryState)
    let batteryLevel: Int = UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : -1
    let applicationState: UIApplicationState = UIApplication.shared.applicationState
    let userAbsoluteDistanceToDestination: CLLocationDistance?
    let locationEngine: CLLocationManager.Type?
    let percentTimeInPortrait: Int
    let percentTimeInForeground: Int
    let locationManagerDesiredAccuracy: CLLocationAccuracy?
    
    let stepIndex: Int
    let stepCount: Int
    let legIndex: Int
    let legCount: Int
    let totalStepCount: Int
    
    var event: String?
    var arrivalTimestamp: Date?
    var rating: Int?
    var comment: String?
    var userId: String?
    var feedbackType: String?
    var description: String?
    var screenshot: String?
    var secondsSinceLastReroute: TimeInterval?
    var newDistanceRemaining: CLLocationDistance?
    var newDurationRemaining: TimeInterval?
    var newGeometry: String?
    var routeLegProgress: RouteLegProgress?
    
    init(routeController: RouteController, session: SessionState) {
        
        startTimestamp = session.departureTimestamp ?? nil
        sdkIdentifier = routeController.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        profile = routeController.routeProgress.route.routeOptions.profileIdentifier.rawValue
        simulation = routeController.locationManager is ReplayLocationManager || routeController.locationManager is SimulatedLocationManager ? true : false
        
        sessionIdentifier = session.identifier.uuidString
        originalRequestIdentifier = session.originalRoute.routeIdentifier
        requestIdentifier = routeController.routeProgress.route.routeIdentifier
        
        let location = routeController.locationManager.location
        coordinate = location?.coordinate ?? nil
        
        if let coordinates = routeController.routeProgress.route.coordinates, let lastCoord = coordinates.last {
            userAbsoluteDistanceToDestination = location?.distance(from: CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)) ?? nil
        } else {
            userAbsoluteDistanceToDestination = nil
        }
        
        if let geometry = session.originalRoute.coordinates {
            originalGeometry = Polyline(coordinates: geometry)
            originalDistance = round(session.originalRoute.distance)
            originalEstimatedDuration = round(session.originalRoute.expectedTravelTime)
            originalStepCount = session.originalRoute.legs.map({$0.steps.count}).reduce(0, +)
        } else {
            originalGeometry = nil
            originalDistance = nil
            originalEstimatedDuration = nil
            originalStepCount = nil
        }
        
        if let geometry = session.currentRoute.coordinates {
            self.geometry = Polyline(coordinates: geometry)
            distance = round(session.currentRoute.distance)
            estimatedDuration = round(session.currentRoute.expectedTravelTime)
        } else {
            self.geometry = nil
            distance = nil
            estimatedDuration = nil
        }
        
        distanceCompleted = round(session.totalDistanceCompleted + routeController.routeProgress.distanceTraveled)
        distanceRemaining = round(routeController.routeProgress.distanceRemaining)
        durationRemaining = round(routeController.routeProgress.durationRemaining)
        
        rerouteCount = session.numberOfReroutes
        
        
        if let manager = routeController.locationManager {
            locationEngine = type(of: manager)
            locationManagerDesiredAccuracy = manager.desiredAccuracy
        } else {
            locationEngine = nil
            locationManagerDesiredAccuracy = nil
        }
        
        var totalTimeInPortrait = session.timeSpentInPortrait
        var totalTimeInLandscape = session.timeSpentInLandscape
        if UIDevice.current.orientation.isPortrait {
            totalTimeInPortrait += abs(session.lastTimeInPortrait.timeIntervalSinceNow)
        } else if UIDevice.current.orientation.isLandscape {
            totalTimeInLandscape += abs(session.lastTimeInLandscape.timeIntervalSinceNow)
        }
        percentTimeInPortrait = totalTimeInPortrait + totalTimeInLandscape == 0 ? 100 : Int((totalTimeInPortrait / (totalTimeInPortrait + totalTimeInLandscape)) * 100)
        
        var totalTimeInForeground = session.timeSpentInForeground
        var totalTimeInBackground = session.timeSpentInBackground
        if UIApplication.shared.applicationState == .active {
            totalTimeInForeground += abs(session.lastTimeInForeground.timeIntervalSinceNow)
        } else {
            totalTimeInBackground += abs(session.lastTimeInBackground.timeIntervalSinceNow)
        }
        percentTimeInForeground = totalTimeInPortrait + totalTimeInLandscape == 0 ? 100 : Int((totalTimeInPortrait / (totalTimeInPortrait + totalTimeInLandscape) * 100))
        
        stepIndex = routeController.routeProgress.currentLegProgress.stepIndex
        stepCount = routeController.routeProgress.currentLeg.steps.count
        legIndex = routeController.routeProgress.legIndex
        legCount = routeController.routeProgress.route.legs.count
        totalStepCount = routeController.routeProgress.route.legs.map { $0.steps.count }.reduce(0, +)
    }
    
    private enum CodingKeys: String, CodingKey {
        case originalRequestIdentifier
        case requestIdentifier
        case latitude = "lat"
        case longitude = "lng"
        case originalGeometry
        case originalDistance
        case originalEstimatedDuration
        case originalStepCount
        case geometry
        case distance
        case estimatedDuration
        case created
        case startTimestamp
        case sdkIdentifier
        case sdkVersion
        case profile
        case simulation
        case sessionIdentifier
        case distanceCompleted
        case distanceRemaining
        case durationRemaining
        case rerouteCount
        case volumeLevel
        case audioType
        case screenBrightness
        case batteryPluggedIn
        case batteryLevel
        case applicationState
        case userAbsoluteDistanceToDestination
        case locationEngine
        case percentTimeInPortrait
        case percentTimeInForeground
        case locationManagerDesiredAccuracy
        case stepIndex
        case stepCount
        case legIndex
        case legCount
        case totalStepCount
        case event
        case arrivalTimestamp
        case rating
        case comment
        case userId
        case feedbackType
        case description
        case screenshot
        case secondsSinceLastReroute
        case newDistanceRemaining
        case newDurationRemaining
        case newGeometry
        case routeLegProgress = "step"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(originalRequestIdentifier, forKey: .originalRequestIdentifier)
        try container.encodeIfPresent(requestIdentifier, forKey: .requestIdentifier)
        try container.encodeIfPresent(coordinate?.latitude, forKey: .latitude)
        try container.encodeIfPresent(coordinate?.longitude, forKey: .longitude)
        try container.encodeIfPresent(originalGeometry?.encodedPolyline, forKey: .originalGeometry)
        try container.encodeIfPresent(originalDistance, forKey: .originalDistance)
        try container.encodeIfPresent(originalEstimatedDuration, forKey: .originalEstimatedDuration)
        try container.encodeIfPresent(geometry?.encodedPolyline, forKey: .geometry)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(created.ISO8601, forKey: .created)
        try container.encodeIfPresent(startTimestamp, forKey: .startTimestamp)
        try container.encode(sdkIdentifier, forKey: .sdkIdentifier)
        try container.encode(sdkVersion, forKey: .sdkVersion)
        try container.encode(profile, forKey: .profile)
        try container.encode(simulation, forKey: .simulation)
        try container.encode(sessionIdentifier, forKey: .sessionIdentifier)
        try container.encode(distanceCompleted, forKey: .distanceCompleted)
        try container.encode(distanceRemaining, forKey: .distanceRemaining)
        try container.encode(durationRemaining, forKey: .durationRemaining)
        try container.encode(rerouteCount, forKey: .rerouteCount)
        try container.encode(volumeLevel, forKey: .volumeLevel)
        try container.encode(audioType, forKey: .audioType)
        try container.encode(screenBrightness, forKey: .screenBrightness)
        try container.encode(batteryPluggedIn, forKey: .batteryPluggedIn)
        try container.encode(batteryLevel, forKey: .batteryLevel)
        try container.encode(applicationState, forKey: .applicationState)
        try container.encodeIfPresent(userAbsoluteDistanceToDestination, forKey: .userAbsoluteDistanceToDestination)
        if let locationEngine = locationEngine {
            try container.encode(String(describing: locationEngine), forKey: .locationEngine)
        }
        try container.encode(percentTimeInPortrait, forKey: .percentTimeInPortrait)
        try container.encode(percentTimeInForeground, forKey: .percentTimeInForeground)
        try container.encodeIfPresent(locationManagerDesiredAccuracy, forKey: .locationManagerDesiredAccuracy)
        try container.encode(stepIndex, forKey: .stepIndex)
        try container.encode(stepCount, forKey: .stepCount)
        try container.encode(legIndex, forKey: .legIndex)
        try container.encode(legCount, forKey: .legCount)
        try container.encode(totalStepCount, forKey: .totalStepCount)
        try container.encodeIfPresent(event, forKey: .event)
        try container.encodeIfPresent(arrivalTimestamp?.ISO8601, forKey: .arrivalTimestamp)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(feedbackType, forKey: .feedbackType)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encodeIfPresent(secondsSinceLastReroute, forKey: .secondsSinceLastReroute)
        try container.encodeIfPresent(newDistanceRemaining, forKey: .newDistanceRemaining)
        try container.encodeIfPresent(newDurationRemaining, forKey: .newDurationRemaining)
        try container.encodeIfPresent(routeLegProgress, forKey: .routeLegProgress)
    }
}

extension RouteLegProgress: Encodable {
    
    private enum CodingKeys: String, CodingKey {
        case upcomingInstruction
        case upcomingType
        case upcomingModifier
        case upcomingName
        case previousInstruction
        case previousType
        case previousModifier
        case previousName
        case distance
        case duration
        case distanceRemaining
        case durationRemaining
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(upComingStep?.instructions, forKey: .upcomingInstruction)
        try container.encodeIfPresent(upComingStep?.maneuverType.description, forKey: .upcomingType)
        try container.encodeIfPresent(upComingStep?.maneuverDirection.description, forKey: .upcomingModifier)
        try container.encodeIfPresent(upComingStep?.names?.joined(separator: ";"), forKey: .upcomingName)
        try container.encodeIfPresent(currentStep.instructions, forKey: .previousInstruction)
        try container.encode(currentStep.maneuverType.description, forKey: .previousType)
        try container.encode(currentStep.maneuverDirection.description, forKey: .previousModifier)
        try container.encode(currentStep.names?.joined(separator: ";"), forKey: .previousName)
        try container.encode(Int(currentStep.distance), forKey: .distance)
        try container.encode(Int(currentStep.expectedTravelTime), forKey: .duration)
        try container.encode(Int(currentStepProgress.distanceRemaining), forKey: .distanceRemaining)
        try container.encode(Int(currentStepProgress.durationRemaining), forKey: .durationRemaining)
    }
}

extension EventDetails {
    
    enum EventDetailsError: Error {
        case EncodingError(String)
    }
    
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        if let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
            return dictionary
        } else {
            throw EventDetailsError.EncodingError("Failed to encode event details")
        }
    }
    
    static func defaultEvents(routeController: RouteController) -> EventDetails {
        return EventDetails(routeController: routeController, session: routeController.eventsManager.sessionState)
    }
}

extension UIApplicationState: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let stringRepresentation: String
        switch self {
        case .active:
            stringRepresentation = "Foreground"
        case .inactive:
            stringRepresentation = "Inactive"
        case .background:
            stringRepresentation = "Background"
        }
        try container.encode(stringRepresentation)
    }
}

extension AVAudioSession {
    var audioType: String {
        if isOutputBluetooth() {
            return "bluetooth"
        }
        if isOutputHeadphones() {
            return "headphones"
        }
        if isOutputSpeaker() {
            return "speaker"
        }
        return "unknown"
    }
    
    func isOutputBluetooth() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE].contains(output.portType) {
                return true
            }
        }
        return false
    }
    
    func isOutputHeadphones() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortHeadphones, AVAudioSessionPortAirPlay, AVAudioSessionPortHDMI, AVAudioSessionPortLineOut].contains(output.portType) {
                return true
            }
        }
        return false
    }
    
    func isOutputSpeaker() -> Bool {
        for output in currentRoute.outputs {
            if [AVAudioSessionPortBuiltInSpeaker, AVAudioSessionPortBuiltInReceiver].contains(output.portType) {
                return true
            }
        }
        return false
    }
}
