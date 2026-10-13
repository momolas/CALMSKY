//
//  SwiftUIComponentsTests.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import Testing
import SwiftUI
@testable import AstronomyKit

@MainActor
@Suite("SwiftUI Astronomical Components Tests")
struct SwiftUIComponentsTests {

    @Test("CelestialBodyCard initializes with valid snapshot")
    func testCelestialBodyCard() {
        let jd = JulianDay(year: 2026, month: 9, day: 20)
        let snapshot = SolarSystemBody.jupiter.ephemeris(at: jd)

        let card = CelestialBodyCard(snapshot: snapshot)
        #expect(card.snapshot.body == .jupiter)
        #expect(card.snapshot.apparentMagnitude != nil)
    }

    @Test("LunarPhaseView renders correct illumination percentage")
    func testLunarPhaseView() {
        let view = LunarPhaseView(phase: .waxingCrescent, illumination: 0.25, size: 100)
        #expect(view.phase == .waxingCrescent)
        #expect(view.illumination == 0.25)
        #expect(view.size == 100)
    }

    @Test("AstronomicalCoordinatesView displays formatted equatorial coordinates")
    func testAstronomicalCoordinatesView() {
        let coords = EquatorialCoordinates(
            alpha: Hour(12.5),
            delta: Degree(45.25)
        )
        let view = AstronomicalCoordinatesView(coordinates: coords)
        #expect(view.coordinates.rightAscension.value == 12.5)
        #expect(view.coordinates.declination.value == 45.25)
    }

    @Test("ObservationPlannerView initializes without crash")
    func testObservationPlannerView() {
        _ = ObservationPlannerView()
        #expect(ObservationPlannerView.BodyFilter.allCases.count == 3)
    }

    @Test("SolarSystemBody displayColor and CelestialColor interop")
    func testCelestialColorInterop() {
        for body in SolarSystemBody.allCases {
            let color = body.displayColor
            _ = color
        }
        let white = Color(celestialColor: .white)
        _ = white
    }

    @Test("Angle and Radian SwiftUI interop")
    func testAngleInterop() {
        let deg = Degree(45.0)
        let swiftUIAngle = deg.asSwiftUIAngle
        #expect(swiftUIAngle.degrees == 45.0)

        let convertedDeg = Degree(swiftUIAngle)
        #expect(convertedDeg.value == 45.0)

        let rad = Radian(.pi / 2.0)
        let radAngle = rad.asSwiftUIAngle
        #expect(abs(radAngle.radians - .pi / 2.0) < 1e-12)

        let convertedRad = Radian(radAngle)
        #expect(abs(convertedRad.value - .pi / 2.0) < 1e-12)
    }
}
#endif
