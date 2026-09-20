//
//  UranusTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 07/03/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("UranusTests")
struct UranusTests {
    @Test("Average Color Presence")
    func testAverageColorPresence() {
        #expect(Uranus.averageColor != CelestialColor.white)
    }
}
