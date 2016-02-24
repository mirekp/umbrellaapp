//
//  LocationTests.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 22/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import XCTest
import CoreLocation
@testable import umbrellaapp

class LocationTests: XCTestCase {

    // check that Info.plist contains location permission key. The location API doesn't work well without it.
    func testLocationHelperPermissionKeys() {
        //when
        let description = NSBundle.mainBundle().objectForInfoDictionaryKey("NSLocationWhenInUseUsageDescription")
        //then
        XCTAssertNotNil(description, "NSLocationWhenInUseUsageDescription is missing from Info.plist")
    }

    // tests that location helper can be created and that the accuracy isn't unecessarily high
    func testLocationHelperInitAccuracy() {
        // given
        let helper = UMBLocationHelper()
        // then
        XCTAssertGreaterThanOrEqual(helper.locationManager.desiredAccuracy, kCLLocationAccuracyKilometer, "Position accuracy is higher than it should be")
    }
    
    // Mock objects for location testing
    class ViewControllerMock: UMBViewController {
        var _didGetLocationPermission = false
        var _didLostLocationPermission = false
        override func didGetLocationPermission() { _didGetLocationPermission = true }
        override func didLostLocationPermission() { _didLostLocationPermission = true }
    }
    
    class CLLocationManagerMock: CLLocationManager {
        var _requestLocation = false
        override func requestLocation() {
            _requestLocation = true
        }
        
        var _requestWhenInUseAuthorization = false
        override func requestWhenInUseAuthorization() {
            _requestWhenInUseAuthorization = true
        }
        
        override class func authorizationStatus() -> CLAuthorizationStatus {
            return .NotDetermined
        }
        
    }

    // tests that initial requestLocation() triggers autentication request
    func testInitialPermissionRequest() {
        // given
        let viewControllerMock = ViewControllerMock()
        let helper = UMBLocationHelper()
        helper.delegate = viewControllerMock
        let locationManagerMock = CLLocationManagerMock()
        helper.locationManager = locationManagerMock
        helper.locationManager.delegate = helper
        
        // when
        helper.requestLocation()

        // then
        XCTAssertTrue(locationManagerMock._requestWhenInUseAuthorization, "_requestWhenInUseAuthorization not called")
    }
    
    // tests that location helper notifies delegate when gaining/loosing permission
    func testPermissionCallbacks() {
        //given
        let viewControllerMock = ViewControllerMock()
        let helper = UMBLocationHelper()
        helper.delegate = viewControllerMock
        let locationManagerMock = CLLocationManagerMock()
        helper.locationManager = locationManagerMock
        helper.locationManager.delegate = helper
        
        // when
        helper.locationManager(locationManagerMock, didChangeAuthorizationStatus: .Denied)
        helper.locationManager(locationManagerMock, didChangeAuthorizationStatus: .AuthorizedWhenInUse)
        
        //then
        XCTAssertTrue(viewControllerMock._didGetLocationPermission, "didGetLocationPermission not called")
        XCTAssertTrue(viewControllerMock._didLostLocationPermission, "didLostLocationPermission not called")
    }

    // tests that Loc/ationHelper is properly updating Controller using callbacks
    func testThatLocationHelperIsUpdatingViewController() {

        // given
        class ViewControllerMock: UMBViewController {

            var _didUpdatedLocation = false

            override func didUpdateLocation(coordinates: CLLocationCoordinate2D) {
                _didUpdatedLocation = true
            }

            override func didGetLocationPermission() {
            }
        }

        class CLLocationManagerMock: CLLocationManager {
            override var location: CLLocation {
                // should resolve to London
                return CLLocation(latitude: 51.50, longitude: 0.125)
            }
        }

        let viewControllerMock = ViewControllerMock()
        let helper = UMBLocationHelper()
        helper.delegate = viewControllerMock
        let manager = CLLocationManagerMock()

        // when
        helper.locationManager(manager, didUpdateLocations:[manager.location])

        // then
        XCTAssertTrue(viewControllerMock._didUpdatedLocation, "location not updated")
    }

}
