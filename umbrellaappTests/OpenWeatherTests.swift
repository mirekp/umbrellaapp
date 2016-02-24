//
//  OpenWeatherTests.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 22/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import XCTest
import CoreLocation
@testable import umbrellaapp

// this module contains OpenWeather specific test cases

class OpenWeatherTests: XCTestCase {

    // check that Info.plist contains ATS (Application Transport Security) exception for openweather.org if using plaintext HTTP.
    func testThatATSConfigurationIsCorrect() {
        //given
        let openWeather = UMBOpenWeatherDataSource()
        var atsClear = false

        // when
        if openWeather.baseURL.containsString("http://") {
            if let NSAppTransportSecurity = NSBundle.mainBundle().objectForInfoDictionaryKey("NSAppTransportSecurity") as? NSDictionary {
                if let NSExceptionDomains = NSAppTransportSecurity.valueForKey("NSExceptionDomains") as? NSDictionary {
                    if let domain = NSExceptionDomains.valueForKey("api.openweathermap.org") as? NSDictionary {
                        if let NSExceptionAllowsInsecureHTTPLoads = domain.valueForKey("NSExceptionAllowsInsecureHTTPLoads") as? Bool {
                            atsClear = NSExceptionAllowsInsecureHTTPLoads ? true : false
                        }
                    }
                }
            }
        } else if openWeather.baseURL.containsString("https://") {
            // looks like we've moved to https://. Good work!
            atsClear = true
        }

        // then
        XCTAssertTrue(atsClear, "ATS configuration is incorrect")
    }

    // This version of the app supports english and Celsius degrees only for simplicity.
    // Also the app is designed to use OpenWeather 2.5 API
    // This test ensures that this is the above conditions are met to avoid unexpected problems later
    func testOpenWeatherUIConstrain() {
        //given
        let openWeather = UMBOpenWeatherDataSource()
        // when/then
        XCTAssertEqual(openWeather.apiVersion, "2.5", "openWeather module only support API 2.5")
        XCTAssertEqual(openWeather.language, "en", "User interface only supports english")
        XCTAssertEqual(openWeather.temperatureFormat, UMBOpenWeatherDataSource.TemperatureFormat.Celsius, "User interface only supports Celsius degrees")
    }

    // tests that it is possible to generate OpenWeather API URIs with all the required data
    func testOpenWeatherParams() {
        //given
        let openWeather = UMBOpenWeatherDataSource()

        // when
        let uri1 = openWeather.currentWeatherURIForLocation(CLLocationCoordinate2D(latitude: 35, longitude: 139))

        // then
        XCTAssertTrue(uri1.absoluteString.containsString("&APPID=\(openWeather.apiKey)"), "There is no API key in the request")
        XCTAssertTrue(uri1.absoluteString.containsString(openWeather.baseURL), "There is no base URL in the request")
        XCTAssertTrue(uri1.absoluteString.containsString("&lang=\(openWeather.language)"), "There is no language in the request")

        XCTAssertEqual(openWeather.language, "en", "User interface only supports english")
        XCTAssertEqual(openWeather.temperatureFormat, UMBOpenWeatherDataSource.TemperatureFormat.Celsius, "User interface only supports Celsius degrees")
    }

    // tests that it is possible to generate a valid requests for current weather using coordinates
    func testCurrentWeatherURIForLocation() {
        //given
        let openWeather = UMBOpenWeatherDataSource()

        // when
        let uri1 = openWeather.currentWeatherURIForLocation(CLLocationCoordinate2D(latitude: 35, longitude: 139))
        let uri2 = openWeather.currentWeatherURIForLocation(CLLocationCoordinate2D(latitude: -35.56, longitude: -139.56))
        let uri3 = openWeather.currentWeatherURIForLocation(CLLocationCoordinate2D(latitude: 0, longitude: 0))
        let uri4 = openWeather.currentWeatherURIForLocation(CLLocationCoordinate2D(latitude: -90, longitude: -180))

        // then
        XCTAssertTrue(uri1.absoluteString.containsString("/weather?lat=35.0&lon=139.0"))
        XCTAssertTrue(uri2.absoluteString.containsString("/weather?lat=-35.56&lon=-139.56"))
        XCTAssertTrue(uri3.absoluteString.containsString("/weather?lat=0.0&lon=0.0"))
        XCTAssertTrue(uri4.absoluteString.containsString("/weather?lat=-90.0&lon=-180.0"))
    }

    // tests that it is possible to generate a valid requests for weather forecast using coordinates
    func testWeatherForecastURIForLocation() {
        //given
        let openWeather = UMBOpenWeatherDataSource()

        // when
        let uri1 = openWeather.weatherForecastURIForLocation(CLLocationCoordinate2D(latitude: 35, longitude: 139))
        let uri2 = openWeather.weatherForecastURIForLocation(CLLocationCoordinate2D(latitude: -35.56, longitude: -139.56))

        // then
        XCTAssertTrue(uri1.absoluteString.containsString("/forecast?lat=35.0&lon=139.0"))
        XCTAssertTrue(uri2.absoluteString.containsString("/forecast?lat=-35.56&lon=-139.56"))
    }

    // tests generation of a complete request URL (incl. method and all params)
    func testThatCompleteURICanBeGenerated() {
        // given
        let openWeather = UMBOpenWeatherDataSource()
        openWeather.baseURL = "http://api.openweathermap.org/data/"
        openWeather.apiVersion = "2.5"
        openWeather.apiKey = "85b211beb702eaa1c4f915bb7836c32c"
        openWeather.temperatureFormat = UMBOpenWeatherDataSource.TemperatureFormat.Celsius
        openWeather.language = "en"
        
        // when
        let uri1 = openWeather.weatherForecastURIForLocation(CLLocationCoordinate2D(latitude: 55.755, longitude: 37.62)).absoluteString
        
        // then
        let completeString = "http://api.openweathermap.org/data/2.5/forecast?lat=55.755&lon=37.62&APPID=85b211beb702eaa1c4f915bb7836c32c&lang=en&units=metric"
        XCTAssertEqual(completeString, uri1)
    }

    // tests whether Openwather's rain condition codes can be properly translated to internal rain type
    // http://openweathermap.org/weather-conditions
    func testWeatherConditionTranslationToRain() {
        //given
        let openWeather = UMBOpenWeatherDataSource()

        let rainCodes = [ 200, 201, 202, 210, 211, 212, 221, 230, 231, 232, 300, 301, 302, 310, 311, 312, 313, 314, 321, 500, 501, 502, 503, 504, 511, 520, 521, 522, 531 ]

        for code in rainCodes {

        // when
            let convertedCode = openWeather.convertWeatherCondition(code)

        // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.Rain, "Wrong mapping of code \(code)")
        }
    }

    // tests whether Openwather's snow condition codes can be properly translated to internal snow type
    func testWeatherConditionTranslationToSnow() {
        //given
        let openWeather = UMBOpenWeatherDataSource()

        let snowCodes = [ 600, 601, 602, 611, 612, 615, 616, 620, 621, 622 ]

        for code in snowCodes {
        // when
            let convertedCode = openWeather.convertWeatherCondition(code)
        // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.Snow, "Wrong mapping of code \(code)")
        }
    }

    // tests whether Openwather's clear condition codes can be properly translated to internal sunny type
    func testWeatherConditionTranslationToSunny() {
        //given
        let openWeather = UMBOpenWeatherDataSource()
        let sunnyCodes = [ 800 ]

        for code in sunnyCodes {
        // when
            let convertedCode = openWeather.convertWeatherCondition(code)
        // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.Sunny, "Wrong mapping of code \(code)")
        }
    }

    func testThatSunnyConvertsToClearSkyAtNight() {
        //given
        let openWeather = UMBOpenWeatherDataSource()
        let sunnyCodes = [ 800 ]

        for code in sunnyCodes {
            // when
            let convertedCode = openWeather.convertWeatherCondition(code, night: true)
            // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.ClearNight, "Wrong mapping of code \(code)")
        }
    }

    // tests whether Openwather's cloud condition codes can be properly translated to internal cloudy type
    func testWeatherConditionTranslationToCloudy() {
        //given
        let openWeather = UMBOpenWeatherDataSource()
        let partlyCloudyCodes = [ 801 ]
        let cloudyCodes = [ 802, 803, 804 ]

        for code in partlyCloudyCodes {
        // when
            let convertedCode = openWeather.convertWeatherCondition(code)
        // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.PartlyCloudy, "Wrong mapping of code \(code)")
        }

        for code in cloudyCodes {
        // when
            let convertedCode = openWeather.convertWeatherCondition(code)
        // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.Cloudy, "Wrong mapping of code \(code)")
        }
    }

    // tests mapping of extreme/special condition codes
    func testWeatherConditionTranslationToExtreme() {
        //given

        let openWeather = UMBOpenWeatherDataSource()
        let extremeCodes = [ 900, 901, 902, 903, 904, 905, 906, 951, 952, 953, 954, 955, 956, 957, 958, 959, 960, 961, 962 ]

        for code in extremeCodes {
        // when
            let convertedCode = openWeather.convertWeatherCondition(code)
        // then
            XCTAssertEqual(convertedCode, UMBweatherCondition.Extreme, "Wrong mapping of code \(code)")
        }
    }

    // tests that is is possible to properly decode a full valid response with current weather to UMBWeatherData structure
    // currentweather-validreply.json is a reference example reply from http://openweathermap.org/current
    func testThatValidOpenCurrentWeatherCanBeDecoded() {

        //given
        let openWeather = UMBOpenWeatherDataSource()
        let referenceFile = NSBundle(forClass: self.dynamicType).pathForResource("currentweather-validreply", ofType: "json")
        assert(referenceFile != nil, "Unable to read reference file")
        let data = NSData(contentsOfFile:referenceFile!)
        let dictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary

        // when
        do {
            let weather = try openWeather.processWeatherSection(dictionary)

        // then
        XCTAssertEqual(weather.description, "broken clouds", "Description not decoded properly")
        XCTAssertEqual(weather.temperature, 293.25, "Temperature not decoded properly")
        XCTAssertEqual(weather.condition, UMBweatherCondition.Cloudy, "Weather condition not decoded properly")

        } catch _ {
            XCTFail("Exception in processCurrentWeatherResponse")
        }
    }

    // tests that is is possible to properly decode full valid response with weather forecast to UMBWeatherData structure
    // weatherforecast-validreply is a reference exaple reply obtained by requesting:
    // http://api.openweathermap.org/data/2.5/forecast?q=London,us&appid=...
    func testThatValidOpenWeatherForecastResponseCanBeDecoded() {
        //given
        let openWeather = UMBOpenWeatherDataSource()
        let referenceFile = NSBundle(forClass: self.dynamicType).pathForResource("weatherforecast-validreply", ofType: "json")
        assert(referenceFile != nil, "Unable to read reference file")
        let data = NSData(contentsOfFile:referenceFile!)
        let dict = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary

        // when
        do {
            let weatherPoints1 = try openWeather.processWeatherForecastResponse(dict, entries: 1)
            let weatherPoints3 = try openWeather.processWeatherForecastResponse(dict, entries: 3)

        // then
            XCTAssertTrue(weatherPoints1.count == 1, "Wrong number of entries")
            XCTAssertTrue(weatherPoints3.count == 3, "Wrong number of entries")

        } catch _ {
            XCTFail("Unexpected exception in processWeatherForecastResponse")
        }
    }
    
    // a negative test case to check that exception is thrown when processing an incomplete (but still parseable) reply
    func testThatInvalidResponseTriggersException() {
        
        //given
        let openWeather = UMBOpenWeatherDataSource()
        let referenceFile = NSBundle(forClass: self.dynamicType).pathForResource("invalidreply", ofType: "json")
        assert(referenceFile != nil, "Unable to read reference file")
        let data = NSData(contentsOfFile:referenceFile!)
        let dictionary = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
        
        // when
        do {
            _ = try openWeather.processWeatherSection(dictionary)
            
            // then
            XCTFail("Should raise an exception")
            
        } catch _ {
        }
    }
}
