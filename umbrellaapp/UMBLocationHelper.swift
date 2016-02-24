//
//  LocationHelper.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 18/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import CoreLocation

// MARK: UMBLocationDelegate protocol
// this protocol is designed to be adopted by ViewController (or any other objects) interested in location data

@objc protocol UMBLocationDelegate {
    // Invoked when the location is established or changes
    optional func didUpdateLocation(coordinates: CLLocationCoordinate2D)

    // Invoked when user revokes permissions to the location services
    optional func didLostLocationPermission()
    
    // Invoked when the app re-gains location services permission
    optional func didGetLocationPermission()
}

// MARK: - UMBLocationHelper class

class UMBLocationHelper: NSObject, CLLocationManagerDelegate {

    weak var delegate: UMBLocationDelegate?
    var locationManager: CLLocationManager
    var lastLocation: CLLocationCoordinate2D?
    var lastUpdated: NSDate?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 3000.0;
        locationManager.delegate = self
    }

    // MARK: CLLocationManager callbacks

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        DLog()
        switch (status) {
            case .Denied, .Restricted:
                delegate?.didLostLocationPermission?()
                break
            case .AuthorizedWhenInUse, .AuthorizedAlways:
                delegate?.didGetLocationPermission?()
                break
            default:
                break
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        DLog()
        if let location = manager.location {

            lastLocation = location.coordinate

            // do not send location updates too often, sadly desiredAccuracy/distanceFilter
            // doesn't work very well
            if lastUpdated != nil {
                let elapsedTime = NSDate().timeIntervalSinceDate(lastUpdated!)
                if elapsedTime < 10.0 {
                    DLog("filtering update")
                    return
                }
            }
            
            // notify delegate that we have coordinates so that it can start using them
            self.delegate?.didUpdateLocation?(location.coordinate)
            lastUpdated = NSDate()
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        DLog(error.debugDescription)
    }

    // MARK: exposed helper methods
    
    func requestLocation() {

        // Ask for permission if hasn't been done already.
        // The best practice is to delay the moment of asking for permission to the point when
        // it is actually required. User is then more likely to grant the permission.
        // The actual message shown is specified in Info.plist

        // classForCoderis used rather than CLLocationManager for easier test mocking
        let status = locationManager.classForCoder.authorizationStatus()
        
        if status == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
             DLog("requesting location")
            locationManager.requestLocation()
        } else {
            // do nothing as we have no permission
            delegate?.didLostLocationPermission?()
        }
    }

}
