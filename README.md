# umbrellaapp
Instructions

`git clone https://github.com/mirekp/umbrellaapp.git`

It might be necessary to select different developer team identity in project settings

General notes

- This is a coding sample.
- A very simple minimalist Weather App - opens and display weather at your location + day forecast.
- Runs on iOS 9.0 and up (due to using UIStackView and convenient single-shot requestLocation() API )
- 100% Swift code. Should compile fine in Xcode 7.2.1 against iOS 9.2 SDK
- the app needs location services permission and network access to work
- I’d have a million of ideas about how to extend the app (Fahrenheit degrees, better assets, recognise more condition, expose even more weather data, Reachability for checking network access, …), but the implementation was sandboxed to roughly two days

Implementation notes:

- the app uses MVC architecture
- thorough the implementation the delegation pattern is used to avoid tight coupling, ensure extensibility and testability
- protocols are being used to formalise interfaces between classes
- graphic assets are from https://openclipart.org
- no other 3rd party components are being used
- in selected calls, Swift 2.0 exception error handling is used

Notes about testing:

  - implemented using TDD techniques with multiple interleaved test/implementation stages
  - all unit tests are in XCTest framework
  - test cases use given/then/then structure (setup -> execute tested code -> evaluation)
  - naming convention follows “testThat…” naming convention to document their purpose.
  - various level of tests:
    - static tests checking expected output of a function
    - object mocking/dummy stubs to test interaction between model and controller classes
    - asynchronous end-end tests using XCTestExpectation fullfillments
    - a handful of negative tests (to check if error handling mechanisms are working properly)
    - in addition to tests, there are also test harnesses in the implementation to improve testability. These include:
      - assert() guards to sanitise inputs
      - embedded list in enumeration
      - ...

Ideas for further improvements in test area:
  - Due to simplistic UI (single view app with no controls) there are no UI tests. There could be one or two.
  - performance tests using measureBlock() (although there is probably a little point)
  - some elements (such as actual location permission requests) are difficult to test. It should be possible to add a more sophisticased mocking

Extensibility:

  - UI is implemented in Storyboard using auto-layout. The app is designed for iPhone, but it should be possible to extend UI to other devices (iPad)
  - Different weather services can be introduced. These can be added by implementing UMBWeatherDataSource protocol.
  - Openweather API params are parametrised. They can be easily changes (in case of changing API key, URL, API level,. etc.). After potential future update of API 
  - Using UIStackView UI can be easily extended to display more information (temperature, wind). 
