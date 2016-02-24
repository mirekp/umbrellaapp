//
//  WeatherFetcherTests.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 23/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import XCTest
import CoreLocation
@testable import umbrellaapp

class WeatherFetcherTests: XCTestCase {
    

    // end-end test that checks that we can request wather forecast data, they can be parsed and viewcontroller is notified about the result
    func testThatWeatherForecastCanBeRetrieved() {
        
        // given
        class ViewControllerMock: UMBViewController {
            
            var didFetchWeatherExpectation: XCTestExpectation?
            
            override func didFetchWeatherForecast(forecast:[UMBWeatherData]) {
                XCTAssertTrue(NSThread.isMainThread(), "Callback should be delivered on main thread")
                XCTAssertEqual(forecast.count, 4, "Not enough replies in the data")
                didFetchWeatherExpectation!.fulfill()
            }
        }
        
        let viewControllerMock = ViewControllerMock()
        viewControllerMock.didFetchWeatherExpectation = expectationWithDescription("didFetchWeatherExpectation")
        let weatherFetcher = UMBWeatherFetcher()
        weatherFetcher.delegate = viewControllerMock
        viewControllerMock.weatherFetcher = weatherFetcher
        
        // when
        weatherFetcher.requestWeatherForecast(CLLocation(latitude: 51.50, longitude: 0.125).coordinate)
        
        // then
        waitForExpectationsWithTimeout(15) { error in
            XCTAssertNil(error, "Weather not updated")
        }
    }

    // test that UMBWeatherFetcherDelegate is notified about the error when getting data fails
    func testThaFetcherDelegateIsNotifiedAboutFailure() {

        // given
        class ViewControllerMock: UMBViewController {

            var didFailExpectation: XCTestExpectation?

            override func didFailToFetchData() {
                XCTAssertTrue(NSThread.isMainThread(), "Callback should be delivered on main thread")
                didFailExpectation!.fulfill()
            }
        }

        let viewControllerMock = ViewControllerMock()
        viewControllerMock.didFailExpectation = expectationWithDescription("didFailExpectation")
        let weatherFetcher = UMBWeatherFetcher()
        let openWatherDataSource = UMBOpenWeatherDataSource()
        weatherFetcher.dataSource = openWatherDataSource
        weatherFetcher.delegate = viewControllerMock
        viewControllerMock.weatherFetcher = weatherFetcher

        // when
        openWatherDataSource.apiKey = "invalid_key"
        weatherFetcher.requestWeatherForecast(CLLocation(latitude: 51.50, longitude: 0.125).coordinate)

        // then
        waitForExpectationsWithTimeout(15) { error in
            XCTAssertNil(error, "Weather not updated")
        }
    }
}
