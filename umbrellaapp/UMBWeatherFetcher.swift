//
//  UMBWeatherFetcher.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 20/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - various weather related entities
enum UMBweatherCondition {
    case Sunny
    case ClearNight
    case PartlyCloudy
    case Cloudy
    case Rain
    case Snow
    case Warm
    case Wind
    case Extreme
    case Atmosphere

    // list of all condition types - useful for enumeration during testing
    static let allConditions = [ Sunny, ClearNight, PartlyCloudy, Cloudy, Rain, Snow, Wind, Extreme, Atmosphere ]
}

// MARK: - UMBWeatherData
//
// UMBWeatherData is a structure used for exchanging simple weather data between model objects and UI
//
struct UMBWeatherData {
    var locationName: String?
    var time: NSDate?
    var condition: UMBweatherCondition?
    var description: String?
    var temperature: Float?
}

// MARK: - UMBWeatherDelegate protocol
// 
// UMBWeatherFetcherDelegate is a delegate for presenting data in UI and notifying it about
// issues. Typically it is a UIViewController that controls UI.
//
protocol UMBWeatherFetcherDelegate: class {
    func didFetchWeatherForecast(forecast: [UMBWeatherData])
    func didFailToFetchData()
}

// MARK: - UMBWeatherDataSource protocol
//
// UMBWeatherDataSource defines a set of requirements for UMBDataSource. Adopting the protocol
// enables creating new data source types (such as a new weather service)
//
protocol UMBWeatherDataSource {
    // creates NSURL of request for current weather
    func currentWeatherURIForLocation(coordinate: CLLocationCoordinate2D) -> NSURL
    
    // creates NSURL of request for weather forecast
    func weatherForecastURIForLocation(coordinate: CLLocationCoordinate2D) -> NSURL
    
    // parses reply data in NSDictionary format to array of UMBWeatherData structure.
    func processWeatherForecastResponse(response: NSDictionary, entries: Int) throws -> [ UMBWeatherData ]
}

// MARK: - UMBWeatherFetcher class
// UMBWeather is a model object for facilitating retrieval of weather data.
// It contains functions to execute and process RESTful queries to services.
// It is the interface point to the presentation controller.
// It doesn't implement any specific API. Services are expected to be specified
// by providing dataSource delegates.

class UMBWeatherFetcher {

    // MARK: utility functions to support query processing and JSON parsing
    
    // Result is a generic return type returned by performRequest
    // it contains result of the request and encapsulates NSURLResponse and data object (NSDictionary) (request succesful)
    // and NSURLResponse + NSError (in case of network error or JSON parsing error)
    enum Result {
        case Success(NSURLResponse!, NSDictionary!)
        case Error(NSURLResponse!, NSError!)

        func data() -> NSDictionary? {
            switch self {
                case .Success(_, let dictionary):
                    return dictionary
                case .Error(_, _):
                    return nil
            }
        }

        func response() -> NSURLResponse? {
            switch self {
                case .Success(let response, _):
                    return response
                case .Error(let response, _):
                    return response
                }
        }

        func error() -> NSError? {
            switch self {
                case .Success(_, _):
                    return nil
                case .Error(_, let error):
                    return error
                }
        }
    }

    // a wrapper for getting data from RESTful services using NSURLSession
    func performRequest(url: NSURL, completionBlock: (Result) -> ()) {

        let request = NSURLRequest(URL: url)
        DLog(url.absoluteString)

        let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            var error: NSError? = error
            var dictionary: NSDictionary?

            if data != nil {
                do {
                    dictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as? NSDictionary
                } catch let e as NSError {
                    // if the data received JSON cannot be parsed to NSDictionary
                    DLog("data cannot be parsed")
                    error = e
                }
            }

            // to ensure that the completion block gets always dispatched on the main thread
            NSOperationQueue.mainQueue().addOperationWithBlock {
                var result = Result.Success(response, dictionary)
                if error != nil {
                    result = Result.Error(response, error)
                }
                completionBlock(result)
            }
        }
        dataTask.resume()
    }

    // MARK: delegate and data source

    weak var delegate: UMBWeatherFetcherDelegate?
    var dataSource: UMBWeatherDataSource

    // MARK: initialisers
    
    convenience init() {
        // by default use UMBOpenWeatherDataSource as it is currently the only implemented service
        self.init(dataSource: UMBOpenWeatherDataSource())
    }

    init(dataSource: UMBWeatherDataSource) {
        self.dataSource = dataSource
    }
    
    // MARK: methods invoked by controller to retrieve weather forecast data and pass the result back
    func requestWeatherForecast(coordinates: CLLocationCoordinate2D) {
        
        DLog()
        // it is worth checking that we are still on the planet Earth
        assert(coordinates.latitude >= -90 && coordinates.latitude <= 90, "Invalid latitude")
        assert(coordinates.longitude >= -180 && coordinates.longitude <= 180, "Invalid longitude")
        
        let request = dataSource.weatherForecastURIForLocation(coordinates)
        performRequest(request, completionBlock:{(result: Result!) in
            if (result.error() != nil) {
                self.delegate?.didFailToFetchData()
            } else {
                do {
                    let weatherData = try self.dataSource.processWeatherForecastResponse(result.data()!, entries: 4)
                    self.delegate?.didFetchWeatherForecast(weatherData)
                } catch _ {
                    self.delegate?.didFailToFetchData()
                }
            }
        })
    }

    // MARK: error types
    
    enum fetcherErrors : ErrorType {
        case TooFewEntriesInReply
        case ResultParsingError
    }
}
