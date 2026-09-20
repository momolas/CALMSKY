//
//  PlutoTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-17.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("PlutoTests")
struct PlutoTests {
    
    @Test("Average Color")
    func testAverageColor() {
        #expect(Pluto.averageColor != CelestialColor.white)
    }
        
}
