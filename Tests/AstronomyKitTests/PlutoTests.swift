//
//  PlutoTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-17.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import XCTest
@testable import AstronomyKit

class PlutoTests: XCTestCase {
    
    func testAverageColor() {
        XCTAssertNotEqual(Pluto.averageColor, CelestialColor.white)
    }
        
}
