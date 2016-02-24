//
//  ViewController.swift
//  umbrellaapp
//
//  Created by Mirek Petricek on 18/02/2016.
//  Copyright © 2016 Mirek Petricek. All rights reserved.
//

import UIKit
import CoreLocation

class UMBViewController: UIViewController, UMBWeatherFetcherDelegate, UMBLocationDelegate {

    // MARK: - interface builder outlets


    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var weatherTextLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var forecast1Image: UIImageView!
    @IBOutlet weak var forecast2Image: UIImageView!
    @IBOutlet weak var forecast3Image: UIImageView!
    @IBOutlet weak var refreshButton: UIButton!

    // a flag to specify if the UI contains initial (fake) data
    var gotPlaceholderData = true

    var forecastImages: [UIImageView] {
        return [ forecast1Image, forecast2Image, forecast3Image]
    }

    @IBAction func didPressRefresh(sender: UIButton?) {
        DLog()

        // a simple animation of the button
        UIView.animateWithDuration(2.0, animations: {
            sender?.transform = CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
        }, completion: {finished in
            sender?.transform = CGAffineTransformMakeRotation(0)
        })

        if locationHelper.lastLocation == nil {
            locationHelper.requestLocation()
        } else {
            self.weatherFetcher?.requestWeatherForecast(self.locationHelper.lastLocation!)
        }
    }

    var locationHelper: UMBLocationHelper!
    var weatherFetcher: UMBWeatherFetcher?
    
    // MARK: - ViewController lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gotPlaceholderData = true

        // initialise model objects
        locationHelper = UMBLocationHelper()
        locationHelper.delegate = self

        weatherFetcher = UMBWeatherFetcher()
        weatherFetcher!.delegate = self

        // throw away placeholder images
        weatherImage.image = nil
        forecast1Image.image = nil
        forecast2Image.image = nil
        forecast3Image.image = nil
        weatherTextLabel.text = "Getting your location..."
        temperatureLabel.text = ""

        NSNotificationCenter.defaultCenter().addObserver(locationHelper, selector: "requestLocation",
            name: UIApplicationDidBecomeActiveNotification, object: nil )

    }

    override func viewWillAppear(animated: Bool) {
        DLog()
        super.viewWillAppear(animated)
        locationHelper.requestLocation()
    }

    // MARK: - location callbacks

    func didUpdateLocation(coordinates: CLLocationCoordinate2D) {
        DLog()
        weatherFetcher!.requestWeatherForecast(coordinates)
    }

    func didGetLocationPermission() {
        DLog()
        // permission is a nice thing to have!
        locationHelper.requestLocation()
    }

    func didLostLocationPermission() {

        // user has revoked location permissions
        // Apple says we should stay away from location services now. However, since the app
        // can't work without location the best we can do is to  politely ask the user to
        // consider chaning his mind. To make his live easier showing settings is a good thing to do.
        // BTW: we cannot just re-request the permission programatically

        cityLabel.text = "Unknown location"

        let alert = UIAlertController(title: "Location error", message:"UmbrelaApp needs access to your location. Please grant access in the system settings.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler:{
            (alert: UIAlertAction!) in
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                if let url = settingsUrl {
                    UIApplication.sharedApplication().openURL(url)
                }
            }))

        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - UMBWeatherFetcherDelegate callbacks

    func didFetchWeatherForecast(var forecast:[UMBWeatherData]) {
    
        DLog()
        assert(forecast.count == 4)
        
        let currentWeather = forecast[0]
        weatherImage.image = UMBViewController.imageForWeather(currentWeather.condition!)
        weatherTextLabel.text = currentWeather.description
        temperatureLabel.text = String(format:"%.1f °C", currentWeather.temperature!)
        if currentWeather.locationName != nil {
            cityLabel.text = currentWeather.locationName
        } else {
            cityLabel.text = "Your location"
        }

        for index in 1...3 {
            let weatherData = forecast[index]
            assert(weatherData.condition != nil)
            let imageView = self.forecastImages[index-1]
            imageView.image = UMBViewController.imageForWeather(weatherData.condition!)
        }

        gotPlaceholderData = false
    }

    func didFailToFetchData() {
        // something went wrong when getting data from service
        DLog()
        if gotPlaceholderData {
            weatherTextLabel.text = "Check your network access..."
            temperatureLabel.text = ""
        }
        
        // try again in 15 sec
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(15 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            DLog("Firing postponed request")
            self.weatherFetcher!.requestWeatherForecast(self.locationHelper.lastLocation!)
        }
    }

    // MARK: - utility functions
    // converts weather condition to image to be displayed
    class func imageForWeather(weather: UMBweatherCondition) -> UIImage? {
        switch weather {
            case .Sunny:
                return UIImage.init(named: "sunny-day")
            case .ClearNight:
                return UIImage.init(named: "clear-night")
            case .Cloudy:
                return UIImage.init(named: "cloudy")
            case .PartlyCloudy:
                return UIImage.init(named: "partially-cloudy")
            case .Rain:
                return UIImage.init(named: "rain")
            case .Snow:
                return UIImage.init(named: "snow")
            case .Wind:
                return UIImage.init(named: "windy")
            case .Extreme, .Atmosphere:
                return UIImage.init(named: "extreme")
            default:
                return nil
        }
    }
}
