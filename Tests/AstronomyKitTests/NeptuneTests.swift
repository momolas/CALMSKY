//
//  NeptuneTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-20.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("NeptuneTests")
struct NeptuneTests {

    @Test("Average Color")
    func testAverageColor() {
        #expect(Neptune.averageColor != CelestialColor.white)
    }
}
