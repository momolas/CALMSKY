import Testing
import Foundation
@testable import AstronomyKit

@Suite("Global Standards Integration Tests (SOFA, NOVAS, SGP4)")
struct StandardsIntegrationTests {

    // MARK: - NOVAS / Vector Astrometry Tests

    @Test("Vector3D basic arithmetic and products")
    func testVector3DOperations() {
        let v1 = Vector3D(x: 1.0, y: 0.0, z: 0.0)
        let v2 = Vector3D(x: 0.0, y: 1.0, z: 0.0)

        #expect(v1.length == 1.0)
        #expect(v1.dot(v2) == 0.0)

        let cross = v1.cross(v2)
        #expect(cross == Vector3D(x: 0.0, y: 0.0, z: 1.0))
        #expect(cross.length == 1.0)

        let scaled = v1 * 3.0
        #expect(scaled.x == 3.0)
        #expect(scaled.length == 3.0)

        let angle = v1.angle(to: v2)
        #expect(abs(angle - .pi / 2.0) < 1e-10)
    }

    @Test("Vector3D spherical coordinate roundtrip")
    func testSphericalConversion() {
        let ra = 45.0
        let dec = 30.0
        let dist = 10.0
        let vec = Vector3D.fromSpherical(ra: ra, dec: dec, distance: dist)

        let back = vec.toSpherical
        #expect(abs(back.ra - ra) < 1e-6)
        #expect(abs(back.dec - dec) < 1e-6)
        #expect(abs(back.distance - dist) < 1e-6)
    }

    @Test("AstrometryReductions - Gravitational deflection and aberration")
    func testAstrometryReductions() {
        let starDir = Vector3D(x: 0.0, y: 1.0, z: 0.0)
        let earthPos = Vector3D(x: 1.0, y: 0.0, z: 0.0) // 1 AU from Sun

        let deflected = AstrometryReductions.gravitationalDeflection(bodyPos: starDir, earthPos: earthPos)
        #expect(deflected.length > 0.999999 && deflected.length < 1.000001)

        // Aberration test with typical Earth orbital speed ~0.0172 AU/day
        let earthVel = Vector3D(x: 0.0, y: 0.0172, z: 0.0)
        let apparent = AstrometryReductions.aberration(direction: starDir, observerVelocity: earthVel)
        #expect(apparent.length > 0.999999 && apparent.length < 1.000001)
    }

    // MARK: - SOFA Modern Reference Frames & Time Scales

    @Test("AstronomicalTimeScale - Delta T and scale conversions")
    func testTimeScales() {
        let j2000 = 2451545.0
        let dt = AstronomicalTimeScale.deltaT(for: j2000)
        #expect(dt > 60.0 && dt < 70.0) // J2000 ΔT was ~64 seconds

        let jdUTC = 2451545.0
        let jdTT = AstronomicalTimeScale.utcToTT(jdUTC: jdUTC)
        let backUTC = AstronomicalTimeScale.ttToUTC(jdTT: jdTT)
        #expect(abs(jdUTC - backUTC) < 1e-9)
    }

    @Test("ModernReferenceFrames - Earth Rotation Angle (ERA IAU 2000)")
    func testEarthRotationAngle() {
        // At J2000.0 (UT1 = 2451545.0), ERA = 2π * 0.7790572732640 rad = ~280.46°
        let j2000 = 2451545.0
        let eraDeg = ModernReferenceFrames.earthRotationAngleDegrees(jdUT1: j2000)
        #expect(eraDeg > 280.0 && eraDeg < 281.0)

        // Reversible CIRS <-> TIRS rotation
        let vec = Vector3D(x: 1.0, y: 2.0, z: 3.0)
        let tirs = ModernReferenceFrames.cirsToTirs(cirsVector: vec, jdUT1: j2000)
        let backCirs = ModernReferenceFrames.tirsToCirs(tirsVector: tirs, jdUT1: j2000)
        #expect(abs(vec.x - backCirs.x) < 1e-12)
        #expect(abs(vec.y - backCirs.y) < 1e-12)
        #expect(abs(vec.z - backCirs.z) < 1e-12)
    }

    @Test("ModernReferenceFrames - IAU 2006 Mean Obliquity")
    func testMeanObliquityIAU2006() {
        let j2000 = 2451545.0
        let oblArcsec = ModernReferenceFrames.meanObliquityIAU2006(jdTT: j2000)
        // ε₀ at J2000.0 is exactly 84381.406 arcseconds (~23°26'21.4")
        #expect(abs(oblArcsec - 84381.406) < 1e-3)
    }

    // MARK: - NORAD SGP4 & TLE Satellite Tests

    @Test("TwoLineElements parser with International Space Station (ISS)")
    func testTLEParserWithISS() {
        let issTLE = [
            "ISS (ZARYA)",
            "1 25544U 98067A   24001.50000000  .00016717  00000-0  10270-3 0  9001",
            "2 25544  51.6400 208.1000 0004500  75.3000 284.8000 15.49800000432105"
        ]

        let tle = TwoLineElements.parse(lines: issTLE)
        #expect(tle != nil)
        guard let tle = tle else { return }

        #expect(tle.name == "ISS (ZARYA)")
        #expect(tle.satelliteNumber == 25544)
        #expect(tle.inclinationDegrees == 51.64)
        #expect(tle.meanMotionRevolutionsPerDay == 15.498)
        #expect(tle.semiMajorAxisKm > 6700.0 && tle.semiMajorAxisKm < 6900.0) // LEO ~400km altitude
    }

    @Test("SatellitePropagator - Orbit propagation and look angles")
    func testSatellitePropagation() {
        let issTLE = [
            "ISS (ZARYA)",
            "1 25544U 98067A   24001.50000000  .00016717  00000-0  10270-3 0  9001",
            "2 25544  51.6400 208.1000 0004500  75.3000 284.8000 15.49800000432105"
        ]

        guard let tle = TwoLineElements.parse(lines: issTLE) else {
            Issue.record("Failed to parse ISS TLE")
            return
        }

        // Propagate 1 hour after epoch
        let state = SatellitePropagator.propagate(tle: tle, toJD: tle.epochJulianDate + 1.0 / 24.0)

        // Orbital radius should be around ~6780 km
        let orbitRadius = state.position.length
        #expect(orbitRadius > 6700.0 && orbitRadius < 6900.0)

        // Look angles from Paris (lat: 48.8566, lon: 2.3522)
        let now = Date()
        let look = SatellitePropagator.lookAngles(
            state: state,
            observerLatitude: 48.8566,
            observerLongitude: 2.3522,
            date: now
        )

        #expect(look.altitude >= -90.0 && look.altitude <= 90.0)
        #expect(look.azimuth >= 0.0 && look.azimuth <= 360.0)
        #expect(look.distanceKm > 300.0) // Satellite cannot be inside the Earth
    }
}
