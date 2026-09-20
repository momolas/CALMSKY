//
//  ELP2000Tests.swift
//  AstronomyKitTests
//
//  Unit tests for the pure Swift ELP2000-82B lunar theory.
//

import Testing
import Foundation
@testable import AstronomyKit

@Suite("ELP2000-82B Lunar Theory Tests")
struct ELP2000Tests {

    @Test("ELP2000 fundamental Delaunay arguments computation")
    func testDelaunayArguments() {
        let jd = 2451545.0 // J2000.0 epoch
        let args = CAAELP2000.computeArguments(jd)

        #expect(args.t == 0.0)
        #expect(args.d > 0.0 && args.d < 2.0 * .pi)
        #expect(args.m > 0.0 && args.m < 2.0 * .pi)
        #expect(args.mdash > 0.0 && args.mdash < 2.0 * .pi)
        #expect(args.f > 0.0 && args.f < 2.0 * .pi)
    }

    @Test("ELP2000 coordinates evaluation at reference epoch")
    func testCoordinatesAtEpoch() {
        let jd = 2448724.5 // 1992 April 12.0 TT (Meeus Example 47.a)
        let lon = CAAELP2000.eclipticLongitude(jd)
        let lat = CAAELP2000.eclipticLatitude(jd)
        let dist = CAAELP2000.radiusVector(jd)

        #expect(lon >= 0.0 && lon < 360.0)
        #expect(abs(lon - 133.167) < 0.1)
        #expect(abs(lat - (-3.229)) < 0.1)
        #expect(abs(dist - 368409.7) < 100.0)
    }

    @Test("ELP2000 apparent equatorial coordinates evaluation")
    func testApparentEquatorialCoordinates() {
        let jd = 2461303.5 // 2026-Sep-20
        let coords = CAAELP2000.apparentEquatorialCoordinates(jd)

        #expect(coords.alpha >= 0.0 && coords.alpha < 24.0)
        #expect(coords.delta >= -90.0 && coords.delta <= 90.0)
    }
}
