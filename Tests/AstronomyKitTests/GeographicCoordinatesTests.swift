//
//  GeographicCoordinatesTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

#if canImport(CoreLocation)
import CoreLocation
#endif

@Suite("GeographicCoordinatesTests")
struct GeographicCoordinatesTests {

    #if canImport(CoreLocation)
    @Test("Constructor From CLLocation")
    func testConstructorFromCLLocation() {
        let location = CLLocation(latitude: 10.0, longitude: 20.0)
        let coords = GeographicCoordinates(location)
        #expect(location.coordinate.longitude == -1*coords.longitude.value)
        #expect(location.coordinate.latitude == coords.latitude.value)
    }
    
    @Test("CLLocation Exporter")
    func testCLLocationExporter() {
        let location = CLLocation(latitude: 10.0, longitude: 20.0)
        let coords = GeographicCoordinates(location)
        #expect(location.coordinate.longitude == coords.location.coordinate.longitude)
        #expect(location.coordinate.latitude == coords.location.coordinate.latitude)
    }
    #endif

    // See AA p.84
    @Test("Globe Radii")
    func testGlobeRadii() {
        // Roughly Chicago. AA simply uses latitude = 42º.0.
        let chicago = GeographicCoordinates(positivelyWestwardLongitude: Degree(-87.623177), latitude: Degree(42.0))
        #expect(abs(chicago.globeRadiusOfCurvature.value - 6364033.0) <= 10.0)
        #expect(abs(chicago.globeRadiusOfParallelOfLatitude.value - 4747001.0) <= 10.0)
    }

    // See AA p.85
    @Test("Globe Distance Between Geographic Points")
    func testGlobeDistanceBetweenGeographicPoints() {
        let paris = GeographicCoordinates(positivelyWestwardLongitude: Degree(.minus, 2, 20, 14.0), latitude: Degree(.plus, 48, 50, 11.0))
        let washington = GeographicCoordinates(positivelyWestwardLongitude: Degree(.plus, 77, 03, 56), latitude: Degree(.plus, 38, 55, 17.0))
        #expect(abs(paris.globeDistance(to: washington).value - 6181630.0) <= 10.0)
    }
    
    // See AA p.82
    @Test("Relative Globe Distances To Earth Center")
    func testRelativeGlobeDistancesToEarthCenter() {
        let palomar = GeographicCoordinates(positivelyWestwardLongitude: Degree(.plus, 116, 51, 54.0), latitude: Degree(.plus, 33, 21, 22.0))
        #expect(abs(palomar.rhoSinThetaPrime(forObserverHeight: 1706.0) - 0.546861) <= 0.000001)
        #expect(abs(palomar.rhoCosThetaPrime(forObserverHeight: 1706.0) - 0.836339) <= 0.000001)
    }
}
