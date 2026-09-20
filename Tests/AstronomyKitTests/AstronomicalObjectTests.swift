//
//  AstronomicalObjectTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-24.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
import Foundation
@testable import AstronomyKit

@MainActor
@Suite("AstronomicalObjectTests")
struct AstronomicalObjectTests {

    @Test("Dummy Radius Vector")
    func testDummyRadiusVector() {
        let coords = EquatorialCoordinates(alpha: Hour(.plus, 16, 54, 00.14), delta: Degree(.minus, 39, 50, 44.9))
        AssertEqual(AstronomicalObject(name: "GRO J1655-40", coordinates: coords, julianDay: JulianDay(Date())).radiusVector, AstronomicalUnit(-1))
    }

    @Test("Init Fatal Error", .disabled("fatalError cannot be caught safely in modern Swift Testing"))
    func testInitFatalError() {
        // init(julianDay:highPrecision:) is an un-implemented requirement that triggers fatalError.
    }
}
