//
//  UmbrelaApp.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 19/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import Foundation
import CoreLocation

class UMBOpenWeatherDataSource: UMBWeatherDataSource {

    enum TemperatureFormat: String {
        case Celsius = "metric"
        case Fahrenheit = "imperial"
    }

    // MARK: API key and parameters
    var baseURL = "http://api.openweathermap.org/data/"
    var apiVersion = "2.5"
    var apiKey = "57d778ae73b873b28aa498f5ba7aaa6b"
    var temperatureFormat = TemperatureFormat.Celsius
    var language = "en"

    // MARK: URI translators
    private func makeURIFromOperation(operation: String) -> NSURL {
        let URIString = baseURL + apiVersion + operation + "&APPID=\(apiKey)&lang=\(language)&units=\(temperatureFormat.rawValue)"
        return NSURL(string: URIString)!
    }

    func currentWeatherURIForLocation(coordinate: CLLocationCoordinate2D) -> NSURL {
        
        // it is worth checking that we are still on the planet Earth
        assert(coordinate.latitude >= -90 && coordinate.latitude <= 90, "Invalid latitude")
        assert(coordinate.longitude >= -180 && coordinate.longitude <= 180, "Invalid longitude")
        
        let operationString = "/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)"
        return makeURIFromOperation(operationString)
    }

    func weatherForecastURIForLocation(coordinate: CLLocationCoordinate2D) -> NSURL {
        
        // it is worth checking that we are still on the planet Earth
        assert(coordinate.latitude >= -90 && coordinate.latitude <= 90, "Invalid latitude")
        assert(coordinate.longitude >= -180 && coordinate.longitude <= 180, "Invalid longitude")

        let operationString = "/forecast?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)"
        return makeURIFromOperation(operationString)
    }

    // MARK: Result processors
    // this function does abstraction of complex OpenWeather condition coders to simpler UMBweatherCondition
    // representation
    func convertWeatherCondition(conditionID: Int, night: Bool = false) -> UMBweatherCondition? {
        
        assert(conditionID > 0 && conditionID < 1000, "Unexpected conditionID")
        
        switch (conditionID) {
            case 200...531:
                return .Rain
            case 800:
                return night ? .ClearNight : .Sunny
            case 600...622:
                return .Snow
            case 700...781:
                return .Atmosphere
            case 801:
                return .PartlyCloudy
            case 802...804:
                return .Cloudy
            case 900...962:
                return .Extreme
            default:
                assertionFailure("Unexpected condition \(conditionID)")
                return nil
        }
    }

    /*
    
    q weather section looks like this:
    
    {
    clouds = {
        all = 0;
        };
    dt = 1456164000;
    "dt_txt" = "2016-02-22 18:00:00";
    main = {
        "grnd_level" = "998.0700000000001"; humidity = 92; pressure = "998.0700000000001"; "sea_level" = "1033.31";
        temp = "283.02"; "temp_kf" = "3.31"; "temp_max" = "283.02"; "temp_min" = "279.703";
    };
    sys = {
        pod = d;
    };
    weather = (
        {
        description = "clear sky"; icon = 01d; id = 800;main = Clear;
        }
    );
    wind = {
        deg = "56.004"; speed = "3.46";
        };
    },

    */

    func processWeatherSection(weatherSection: NSDictionary) throws -> UMBWeatherData {

        var weatherData = UMBWeatherData()
        DLog(weatherSection.debugDescription)
        if let mainSection = weatherSection["main"] as? Dictionary<String, AnyObject> {
            if let temp = mainSection["temp"] as? Float? {
                weatherData.temperature = temp
            }
        }

        if let dt = weatherSection["dt"] as? Double {
            weatherData.time = NSDate(timeIntervalSince1970: dt)
        } else {
            throw UMBWeatherFetcher.fetcherErrors.ResultParsingError
        }

        if let weatherSectionArray = weatherSection["weather"] as? [ Dictionary<String, AnyObject> ]? {
            if let firstWeatherSection = weatherSectionArray?.first {
                weatherData.description = firstWeatherSection["description"] as? String
                if let weatherConditionID = firstWeatherSection["id"] as? Int {
                    let hour = NSCalendar.currentCalendar().component(.Hour, fromDate:weatherData.time!)
                    // for simplicity. Would be better to do a proper calculation based on sunset/sunrise
                    let night = hour < 7 || hour > 18
                    weatherData.condition = convertWeatherCondition(weatherConditionID, night: night)
                }
            }
        }

        if weatherData.temperature == nil || weatherData.condition == nil || weatherData.description == nil {
            throw UMBWeatherFetcher.fetcherErrors.ResultParsingError
        }

        return weatherData
    }

    /*
    a response looks like this:
    
    city =     {
        coord =  {
            lat = "39.886452";
            lon = "-83.44825";
        };
        country = US;
        id = 4517009;
        name = London;
        population = 0;
        sys =         {
        population = 0;
        };
    };
    cnt = 40;
    cod = 200;
    
    followed by weather section list = ()

    */

    func processWeatherForecastResponse(response: NSDictionary, entries: Int) throws -> [ UMBWeatherData ] {

        assert(entries > 0, "Unexpected number of entries")
        //DLog(response.debugDescription)
        var cityName: String?
        var weatherArray = [UMBWeatherData]()
        do {

            if let citySection = response["city"] as? NSDictionary {
                cityName = citySection["name"] as? String
            } else {
                throw UMBWeatherFetcher.fetcherErrors.ResultParsingError
            }

            if let dataPointCount = response["cnt"] as? Int {
                if dataPointCount < entries {
                    throw UMBWeatherFetcher.fetcherErrors.TooFewEntriesInReply
                }
            }

            if let weatherSections = response["list"] as? [ NSDictionary ] {

                for weatherSection in weatherSections {
                    let weatherData = try! self.processWeatherSection(weatherSection)
                    weatherArray.append(weatherData)

                    if weatherArray.count == entries {
                        break
                    }
                }
            } else {
                throw UMBWeatherFetcher.fetcherErrors.ResultParsingError
            }
        }

        // insert city name to the first entry
        weatherArray[0].locationName = cityName

        return weatherArray
    }
}
