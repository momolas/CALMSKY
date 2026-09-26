//
//  VectorAstrometryAndAtmosphereTests.swift
//  AstronomyKit
//
//  Created for Phase 9 Modernization.
//  Tests for SIMD Vector3D transformations, Kasten & Young air mass,
//  and Eclipses DTO conversions.
//

import Testing
import simd
import Foundation
@testable import AstronomyKit

@Suite("Vector Astrometry & Atmosphere Modernization Tests")
struct VectorAstrometryAndAtmosphereTests {

    // MARK: - Vector3D SIMD Matrix & Rotation Tests

    @Test("Vector3D SIMD 3x3 Matrix Transformation")
    func testVector3DMatrixTransformation() {
        let v = Vector3D(x: 1.0, y: 2.0, z: 3.0)
        // 90° rotation around Z-axis matrix:
        // [ 0 -1  0 ]
        // [ 1  0  0 ]
        // [ 0  0  1 ]
        let rotZ = simd_double3x3(
            simd_double3(0, 1, 0),   // col 0
            simd_double3(-1, 0, 0),  // col 1
            simd_double3(0, 0, 1)    // col 2
        )
        
        let transformed = v.transformed(by: rotZ)
        let multiplied = rotZ * v
        
        #expect(abs(transformed.x - (-2.0)) < 1e-12)
        #expect(abs(transformed.y - 1.0) < 1e-12)
        #expect(abs(transformed.z - 3.0) < 1e-12)
        
        #expect(abs(multiplied.x - (-2.0)) < 1e-12)
        #expect(abs(multiplied.y - 1.0) < 1e-12)
        #expect(abs(multiplied.z - 3.0) < 1e-12)
    }

    @Test("Vector3D Axis Rotations (X, Y, Z)")
    func testVector3DAxisRotations() {
        let v = Vector3D(x: 1.0, y: 0.0, z: 0.0)
        let halfPi = Double.pi / 2.0
        
        // Rotate around Z by 90°: (1, 0, 0) -> (0, 1, 0)
        let rotZ = v.rotatedZ(angleRadians: halfPi)
        #expect(abs(rotZ.x) < 1e-12)
        #expect(abs(rotZ.y - 1.0) < 1e-12)
        #expect(abs(rotZ.z) < 1e-12)
        
        // Rotate around Y by 90°: (1, 0, 0) -> (0, 0, -1)
        let rotY = v.rotatedY(angleRadians: halfPi)
        #expect(abs(rotY.x) < 1e-12)
        #expect(abs(rotY.y) < 1e-12)
        #expect(abs(rotY.z - (-1.0)) < 1e-12)
        
        // Rotate around X: (0, 1, 0) -> (0, 0, 1)
        let vy = Vector3D(x: 0.0, y: 1.0, z: 0.0)
        let rotX = vy.rotatedX(angleRadians: halfPi)
        #expect(abs(rotX.x) < 1e-12)
        #expect(abs(rotX.y) < 1e-12)
        #expect(abs(rotX.z - 1.0) < 1e-12)
    }

    @Test("StateVector Linear Propagation and Matrix Transformation")
    func testStateVectorOperations() {
        let pos = Vector3D(x: 1.0, y: 0.0, z: 0.0)
        let vel = Vector3D(x: 0.0, y: 0.1, z: 0.0)
        let state = StateVector(position: pos, velocity: vel)
        
        // Propagate by 2 days: pos -> (1.0, 0.2, 0.0)
        let propagated = state.propagated(byTimeDays: 2.0)
        #expect(abs(propagated.position.x - 1.0) < 1e-12)
        #expect(abs(propagated.position.y - 0.2) < 1e-12)
        #expect(abs(propagated.velocity.y - 0.1) < 1e-12)
        
        // Identity transform
        let identity = matrix_identity_double3x3
        let transformed = state.transformed(by: identity)
        #expect(transformed == state)
    }

    @Test("Astrometry Reductions Light Travel Time Helpers")
    func testLightTravelTimeHelpers() {
        // 1 AU distance in days: ~0.0057755 days (~499 seconds)
        let days1AU = AstrometryReductions.lightTravelTimeDays(distanceAU: 1.0)
        let secondsFromDays = days1AU * 86400.0
        #expect(abs(secondsFromDays - 499.0) < 1.0)
        
        // 1 AU in km: 149_597_870.7 km
        let secondsFromKm = AstrometryReductions.lightTravelTimeSeconds(distanceKm: 149_597_870.7)
        #expect(abs(secondsFromKm - 499.0) < 1.0)
    }

    // MARK: - Atmospheric Air Mass & Models Tests

    @Test("Kasten & Young (1989) Air Mass Accuracy")
    func testKastenYoungAirMass() {
        // At zenith (90°): air mass is exactly 1.0
        let zenithX = AtmosphericAirMass.kastenYoungAirMass(trueAltitude: Degree(90.0))
        #expect(abs(zenithX - 1.0) < 1e-3)
        
        // At 30° altitude: air mass is ~2.0
        let midX = AtmosphericAirMass.kastenYoungAirMass(trueAltitude: Degree(30.0))
        #expect(abs(midX - 2.0) < 0.05)
        
        // At 0° altitude (horizon): Kasten & Young gives ~38
        let horizonX = AtmosphericAirMass.kastenYoungAirMass(trueAltitude: Degree(0.0))
        #expect(horizonX > 35.0 && horizonX < 40.0)
        
        // Below horizon (-1°): returns infinity
        let subHorizonX = AtmosphericAirMass.kastenYoungAirMass(trueAltitude: Degree(-1.0))
        #expect(subHorizonX.isInfinite)
    }

    @Test("AirMassModel Enum Dispatching and HorizontalCoordinates extension")
    func testAirMassModelDispatch() {
        let alt = Degree(45.0)
        let pickering = AtmosphericAirMass.airMass(trueAltitude: alt, model: .pickering)
        let kastenYoung = AtmosphericAirMass.airMass(trueAltitude: alt, model: .kastenYoung)
        let rozenberg = AtmosphericAirMass.airMass(trueAltitude: alt, model: .rozenberg)
        
        // At 45°, 1/sin(45°) = sqrt(2) ~ 1.414, all models agree within 0.01
        #expect(abs(pickering - 1.414) < 0.01)
        #expect(abs(kastenYoung - 1.414) < 0.01)
        #expect(abs(rozenberg - 1.414) < 0.01)
        
        let coords = GeographicCoordinates(eastLongitude: Degree(0.0), latitude: Degree(0.0))
        let horiz = HorizontalCoordinates(azimuth: Degree(0.0), altitude: alt, geographicCoordinates: coords, julianDay: JulianDay(2451545.0))
        #expect(abs(horiz.airMass(model: .kastenYoung) - kastenYoung) < 1e-12)
    }

    // MARK: - Eclipses DTO & Convenience Tests

    @Test("Eclipses DTO initializers and Date-based calculation")
    func testEclipsesConvenience() {
        // Solar Eclipse of 1993 May 21
        let solarDetails = CAAEclipses.CalculateSolar(-82.0)
        let solar = SolarEclipseDetails(solarDetails)
        #expect(solar.isPartial)
        #expect(!solar.isTotal)
        #expect(solar.f == solarDetails.F)
        #expect(solar.gamma == solarDetails.gamma)
        
        // Lunar Eclipse of 1973 June 15
        let lunarDetails = CAAEclipses.CalculateLunar(-328.5)
        let lunar = LunarEclipseDetails(lunarDetails)
        #expect(lunar.hasEclipse)
        #expect(lunar.isPenumbral)
        #expect(lunar.penumbralMagnitude == lunarDetails.PenumbralMagnitude)
        
        // Date-based wrapper for 1993 May
        var components = DateComponents()
        components.year = 1993
        components.month = 5
        components.day = 21
        let calendar = Calendar(identifier: .gregorian)
        if let date = calendar.date(from: components) {
            let dateSolar = Eclipses.calculateSolar(at: date)
            #expect(dateSolar.flags.contains(.partial))
        }
    }
}
