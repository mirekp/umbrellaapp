//
//  umbrellaappTests.swift
//  umbrellaappTests
//
//  Created by Mirek Petricek on 18/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import XCTest
import CoreLocation
@testable import umbrellaapp

//
// viewcontroller tests
//

class umbrellaappTests: XCTestCase {

    func testThatViewControllerCreatesModelObjectsAndSetsDelegates() {
        // given
        // need to retain properties as they are defined as weak in the vc class
        let myViewController = UMBViewController()
        let label = UILabel(frame:CGRectZero)
        let imageView = UIImageView(frame:CGRectZero)
        let button = UIButton(frame: CGRectZero)
        myViewController.cityLabel = label
        myViewController.temperatureLabel = label
        myViewController.weatherTextLabel = label
        myViewController.weatherImage = imageView
        myViewController.forecast1Image = imageView
        myViewController.forecast2Image = imageView
        myViewController.forecast3Image = imageView
        myViewController.refreshButton = button

        // when
        myViewController.viewDidLoad()
        let delegate1 = myViewController.locationHelper.delegate
        let delegate2 = myViewController.weatherFetcher?.delegate
        
        // then
        XCTAssertNotNil(myViewController.locationHelper, "locationHelper not created")
        XCTAssertNotNil(myViewController.weatherFetcher, "weatherFetcher not created")
        XCTAssertTrue(delegate1 is UMBViewController, "Not set as a delegate of locationHelper")
        XCTAssertTrue(delegate2 is UMBViewController, "Not set as a delegate of weatherFetcher")
    }
    
    // tests that all weather conditions have corresponding UIImage
    func testIfHavingImagesForAllWeatherConditions() {
        // given
        for condition in UMBweatherCondition.allConditions {
        // when
            let image = UMBViewController.imageForWeather(condition)
        // then
            XCTAssertNotNil(image, "Missing icon for \(condition)")
        }
    }
    
    func testThatAppGetsLocationOnceStarted() {
        // given
        class UMBLocationHelperMock: UMBLocationHelper {
            var _requestLocation = false
            
            override func requestLocation() {
                _requestLocation = true
            }
        }
        let myViewController = UMBViewController()
        let locationHelperMock = UMBLocationHelperMock()
        myViewController.locationHelper = locationHelperMock
        myViewController.locationHelper.delegate = myViewController
        
        // when
        myViewController.viewWillAppear(false)
        
        // then
        XCTAssertTrue(locationHelperMock._requestLocation, "Refresh button did not request location")
    }
    
    // tests that refresh button works
    func testThatRefreshButtonWorks() {
        // given
        class UMBLocationHelperMock: UMBLocationHelper {
            var _requestLocation = false
            
            override func requestLocation() {
                _requestLocation = true
            }
        }
        let myViewController = UMBViewController()
        let locationHelperMock = UMBLocationHelperMock()
        myViewController.locationHelper = locationHelperMock
        myViewController.locationHelper.delegate = myViewController
        
        // when
        myViewController.didPressRefresh(nil)

        // then
        XCTAssertTrue(locationHelperMock._requestLocation, "Refresh button did not request location")
    }
    
    func testThatTheAppGetsWeatherWhenTheLocationIsKnown() {
        // given
        class UMBWeatherFetcherMock: UMBWeatherFetcher {
            var _didRequestCurrentWeather = false
            
            override func requestWeatherForecast(coordinates: CLLocationCoordinate2D) {
                _didRequestCurrentWeather = true
            }
        }
        let myViewController = UMBViewController()
        let weatherFetcherMock = UMBWeatherFetcherMock()
        myViewController.weatherFetcher = weatherFetcherMock
        myViewController.weatherFetcher!.delegate = myViewController
        
        // when
        myViewController.didUpdateLocation(CLLocation(latitude: 51.50, longitude: 0.125).coordinate)
        
        // then
        XCTAssertTrue(weatherFetcherMock._didRequestCurrentWeather, "Refresh button did not request location")
    }
    
    // this test takes at least 15 seconds to execute as it is testing retry timeout
    func testThatFailedRequestIsRetriedAfterTimeOut() {
        
         // given
        class UMBWeatherFetcherMock: UMBWeatherFetcher {
            var didRetryExpectation: XCTestExpectation?
            
            override func requestWeatherForecast(coordinates: CLLocationCoordinate2D) {
                didRetryExpectation!.fulfill()
            }
        }
        let myViewController = UMBViewController()
        let weatherFetcherMock = UMBWeatherFetcherMock()
        myViewController.weatherFetcher = weatherFetcherMock
        myViewController.weatherFetcher!.delegate = myViewController
        weatherFetcherMock.didRetryExpectation = expectationWithDescription("didRetryExpectation")
        myViewController.locationHelper = UMBLocationHelper()
        myViewController.locationHelper.lastLocation = CLLocation(latitude: 51.50, longitude: 0.125).coordinate
        myViewController.gotPlaceholderData = false

        // when
        myViewController.didFailToFetchData()
        
        // then
        waitForExpectationsWithTimeout(18) { error in
            XCTAssertNil(error, "Weather not updated")
        }
    }

    func testThatUIIsUpdatedWhenReceivedForecastData() {
        // given
        let myViewController = UMBViewController()
        let weatherImage = UIImageView.init(frame: CGRectZero)
        let forecast1Image = UIImageView.init(frame: CGRectZero)
        let forecast2Image = UIImageView.init(frame: CGRectZero)
        let forecast3Image = UIImageView.init(frame: CGRectZero)
        let temperatureLabel = UILabel.init(frame: CGRectZero)
        let weatherTextLabel = UILabel.init(frame: CGRectZero)
        let cityLabel = UILabel.init(frame: CGRectZero)

        myViewController.weatherImage = weatherImage
        myViewController.temperatureLabel = temperatureLabel
        myViewController.weatherTextLabel = weatherTextLabel
        myViewController.cityLabel = cityLabel
        myViewController.forecast1Image = forecast1Image
        myViewController.forecast2Image = forecast2Image
        myViewController.forecast3Image = forecast3Image


        let weatherData = [
            UMBWeatherData(locationName: "Hell", time: nil, condition: .Sunny, description: "Sunny day", temperature: 5.5),
            UMBWeatherData(locationName:nil, time: nil, condition: .Cloudy, description: "Disaster", temperature: -5.5),
            UMBWeatherData(locationName:nil, time: nil, condition: .Wind, description: "Apocalypse", temperature: -15.5),
            UMBWeatherData(locationName:nil, time: nil, condition: .Extreme, description: "Global Apocalypse", temperature: -25.5)
        ]

        //when
        myViewController.didFetchWeatherForecast(weatherData)

        //then
        XCTAssertNotNil(myViewController.weatherImage.image)
        XCTAssertEqual(myViewController.cityLabel.text, "Hell")
        XCTAssertEqual(myViewController.temperatureLabel.text, "5.5 °C")
        XCTAssertEqual(myViewController.weatherTextLabel.text, "Sunny day")
        XCTAssertNotNil(myViewController.forecast1Image.image )
        XCTAssertNotNil(myViewController.forecast2Image.image)
        XCTAssertNotNil(myViewController.forecast3Image.image)
    }
}
