//
//  AnglesTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 22/02/2017.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("AnglesTests")
struct AnglesTests {
    @Test("Degree Minus Sign Constructor")
    func testDegreeMinusSignConstructor() {
        XCTAssertEqual(Degree(.minus, 1, 7, 30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, -1, 7, 30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, 1, -7, 30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, 1, 7, -30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, -1, -7, 30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, 1, -7, -30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, -1, 7, -30.0).value, -1.125)
        XCTAssertEqual(Degree(.minus, -1, -7, -30.0).value, -1.125)
    }
    
    @Test("Degree Plus Sign Constructor")
    func testDegreePlusSignConstructor() {
        XCTAssertEqual(Degree(.plus, 1, 7, 30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, -1, 7, 30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, 1, -7, 30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, 1, 7, -30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, -1, -7, 30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, -1, -7, -30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, -1, 7, -30.0).value, 1.125)
        XCTAssertEqual(Degree(.plus, 1, -7, -30.0).value, 1.125)
    }
    
    @Test("Degree Minus Zero Sign Constructor")
    func testDegreeMinusZeroSignConstructor() {
        XCTAssertEqual(Degree(.minus, 0, 7, 30.0).value, -0.125)
        XCTAssertEqual(Degree(.minus, 0, -7, 30.0).value, -0.125)
        XCTAssertEqual(Degree(.minus, 0, 7, -30.0).value, -0.125)
        XCTAssertEqual(Degree(.minus, 0, -7, -30.0).value, -0.125)
        XCTAssertEqual(Degree(.minus, 0, 0, 90.0).value, -0.025)
        XCTAssertEqual(Degree(.minus, 0, 0, -90.0).value, -0.025)
    }
    
    @Test("Degree Plus Zero Sign Constructor")
    func testDegreePlusZeroSignConstructor() {
        XCTAssertEqual(Degree(.plus, 0, 7, 30.0).value, 0.125)
        XCTAssertEqual(Degree(.plus, 0, -7, 30.0).value, 0.125)
        XCTAssertEqual(Degree(.plus, 0, 7, -30.0).value, 0.125)
        XCTAssertEqual(Degree(.plus, 0, -7, -30.0).value, 0.125)
        XCTAssertEqual(Degree(.plus, 0, 0, 90.0).value, 0.025)
        XCTAssertEqual(Degree(.plus, 0, 0, -90.0).value, 0.025)
    }

    @Test("Degree Reduce")
    func testDegreeReduce() {
        AssertEqual(Degree(-370).reduced, Degree(350))
        AssertEqual(Degree(-350).reduced, Degree(10))
        AssertEqual(Degree(-190).reduced, Degree(170))
        AssertEqual(Degree(-10).reduced, Degree(350))
        AssertEqual(Degree(10).reduced, Degree(10))
        AssertEqual(Degree(190).reduced, Degree(190))
        AssertEqual(Degree(350).reduced, Degree(350))
        AssertEqual(Degree(370).reduced, Degree(10))
    }

    @Test("Degree Reduce0")
    func testDegreeReduce0() {
        AssertEqual(Degree(-370).reduced0, Degree(-10))
        AssertEqual(Degree(-350).reduced0, Degree(10))
        AssertEqual(Degree(-190).reduced0, Degree(170))
        AssertEqual(Degree(-10).reduced0, Degree(-10))
        AssertEqual(Degree(10).reduced0, Degree(10))
        AssertEqual(Degree(190).reduced0, Degree(-170))
        AssertEqual(Degree(350).reduced0, Degree(-10))
        AssertEqual(Degree(370).reduced0, Degree(10))
    }

    @Test("Radian Reduce")
    func testRadianReduce() {
        AssertEqual(Radian(-Double.pi-0.1).reduced, Radian(Double.pi-0.1))
        AssertEqual(Radian(-0.1).reduced, Radian(2.0*Double.pi-0.1))
        AssertEqual(Radian(0.1).reduced, Radian(0.1))
        AssertEqual(Radian(Double.pi+0.1).reduced, Radian(Double.pi+0.1))
        AssertEqual(Radian(2.0*Double.pi+0.1).reduced, Radian(0.1), accuracy: Radian(0.00000000000001)) // warf, rounding error?
        AssertEqual(Radian(2.0*Double.pi-0.1).reduced, Radian(2.0*Double.pi-0.1), accuracy: Radian(0.00000000000001)) // warf, rounding error?
    }
    
    @Test("Radian Reduce0")
    func testRadianReduce0() {
        AssertEqual(Radian(-Double.pi-0.1).reduced0, Radian(Double.pi-0.1))
        AssertEqual(Radian(-0.1).reduced0, Radian(-0.1), accuracy: Radian(0.00000000000001)) // warf, rounding error?
        AssertEqual(Radian(0.1).reduced0, Radian(0.1))
        AssertEqual(Radian(Double.pi+0.1).reduced0, Radian(-Double.pi+0.1))
        AssertEqual(Radian(2*Double.pi+0.1).reduced0, Radian(0.1), accuracy: Radian(0.00000000000001)) // warf, rounding error?
        AssertEqual(Radian(2*Double.pi-0.1).reduced0, Radian(-0.1), accuracy: Radian(0.00000000000001)) // warf, rounding error?
    }

    @Test("Degree Sexagesimal Transform")
    func testDegreeSexagesimalTransform() {
        let dplus = Degree(1.125)
        let dplussexagesimal: SexagesimalNotation = (.plus, 1, 7, 30.0)
        #expect(dplus.sexagesimal == dplussexagesimal)
        
        let dminus = Degree(-1.125)
        let dminussexagesimal: SexagesimalNotation = (.minus, 1, 7, 30.0)
        #expect(dminus.sexagesimal == dminussexagesimal)
    }
    
    @Test("Degree Conversions")
    func testDegreeConversions() {
        let d1 = 3.1415
        let d2 = -2.718
        
        #expect(Degree(d1).inArcMinutes.value == d1*60.0)
        #expect(Degree(d2).inArcMinutes.value == d2*60.0)
        
        #expect(Degree(d1).inArcSeconds.value == d1*3600.0)
        #expect(Degree(d2).inArcSeconds.value == d2*3600.0)
        
        #expect(Radian(.pi).inDegrees.value == 180.0)
        #expect(Degree(180.0).inRadians.value == .pi)
    }
    
    @Test("Arc Minute Conversions")
    func testArcMinuteConversions() {
        let d1 = 3.1415
        let d2 = -2.718
        
        #expect(ArcMinute(d1).inDegrees.value == d1/60.0)
        #expect(ArcMinute(d2).inDegrees.value == d2/60.0)
        
        #expect(ArcMinute(d1).inArcSeconds.value == d1*60.0)
        #expect(ArcMinute(d2).inArcSeconds.value == d2*60.0)
    }

    @Test("Arc Second Conversions")
    func testArcSecondConversions() {
        let d1 = 3.1415
        let d2 = -2.718
        
        #expect(ArcSecond(d1).inDegrees.value == d1/3600.0)
        #expect(ArcSecond(d2).inDegrees.value == d2/3600.0)
        
        #expect(ArcSecond(d1).inArcMinutes.value == d1/60.0)
        #expect(ArcSecond(d2).inArcMinutes.value == d2/60.0)
    }

    @Test("Arc Second As Parallax")
    func testArcSecondAsParallax() {
        #expect(ArcSecond(1).distance().value == 1.0)
        #expect(ArcSecond(10).distance().value == 0.1)
    }
    
    @Test("Radian Conversions")
    func testRadianConversions() {
        #expect(Radian(Double.pi).inHours.value == 12.0)
        #expect(Radian(2*Double.pi).inHours.value == 24.0)
    }
    
    @Test("Description Presence")
    func testDescriptionPresence() {
        #expect(!Degree(1.0).description.isEmpty)
        #expect(!ArcMinute(1.0).description.isEmpty)
        #expect(!ArcSecond(1.0).description.isEmpty)
        #expect(!Radian(1.0).description.isEmpty)
    }
}
