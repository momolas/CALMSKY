# Standards and Relativistic Reductions

Learn how AstronomyKit implements global reference standards: USNO NOVAS, IAU SOFA, and NORAD SGP4.

## Overview

In addition to classical analytical theories (Meeus, VSOP87, ELP2000), **AstronomyKit** incorporates core algorithms from global standards:

1. **USNO NOVAS** (*Naval Observatory Vector Astrometry Software*): 3D spatial vectors, relativistic gravitational light deflection, and stellar aberration.
2. **IAU SOFA** (*Standards of Fundamental Astronomy*): Modern time scales ($\Delta T$, TT, TDB, TAI) and intermediate reference systems (CIRS, TIRS, Earth Rotation Angle).
3. **NORAD SGP4**: Artificial satellite tracking from standard Two-Line Element (TLE) sets.

---

## 1. Vector Astrometry (NOVAS)

The ``Vector3D`` and ``StateVector`` types represent positions and velocities in 3D Euclidean space with complete vector arithmetic (`+`, `-`, `*`, `/`, `dot`, `cross`, `angle(to:)`, `distance(to:)`).

```swift
import AstronomyKit

// Convert spherical (RA, Dec in degrees, distance in AU) to 3D Cartesian vector
let starDir = Vector3D.fromSpherical(ra: 45.0, dec: 30.0, distance: 1.0)
let earthPos = Vector3D(x: 1.0, y: 0.0, z: 0.0) // 1 AU from Sun

// Einstein gravitational light deflection by the Sun
let deflected = AstrometryReductions.gravitationalDeflection(
    bodyPos: starDir,
    earthPos: earthPos
)

// Relativistic stellar aberration due to Earth's orbital velocity
let earthVelocity = Vector3D(x: 0.0, y: 0.0172, z: 0.0) // AU / day
let apparentDirection = AstrometryReductions.aberration(
    direction: starDir,
    observerVelocity: earthVelocity
)
```

---

## 2. Modern Reference Frames & Time Scales (IAU SOFA)

Classical algorithms use dynamical ephemeris time. Modern IAU resolutions define non-rotating celestial intermediate frames and relativistic time scales.

### Time Scales and $\Delta T$

``AstronomicalTimeScale`` handles conversions between Universal Time (UTC/UT1) and Terrestrial Time (TT):

```swift
let jdUTC = 2451545.0 // J2000.0

// Compute Delta T = TT - UT1 using Espenak & Meeus (2006)
let deltaTSeconds = AstronomicalTimeScale.deltaT(for: jdUTC) // ~64.09s

// Convert UTC Julian Day to Terrestrial Time
let jdTT = AstronomicalTimeScale.utcToTT(jdUTC: jdUTC)
```

### Earth Rotation Angle & CIRS/TIRS Transformations

``ModernReferenceFrames`` implements the **Earth Rotation Angle (ERA)** according to IAU 2000 resolutions, linking the Celestial Intermediate Reference System (CIRS) to the Terrestrial Intermediate Reference System (TIRS):

```swift
// Earth Rotation Angle (ERA)
let eraDegrees = ModernReferenceFrames.earthRotationAngleDegrees(jdUT1: jdUTC)

// Rotate vector from CIRS to TIRS
let cirsVector = Vector3D(x: 1.0, y: 0.0, z: 0.0)
let tirsVector = ModernReferenceFrames.cirsToTirs(cirsVector: cirsVector, jdUT1: jdUTC)

// Mean obliquity of the ecliptic under IAU 2006
let obliquityArcsec = ModernReferenceFrames.meanObliquityIAU2006(jdTT: jdTT) // 84381.406"
```

---

## 3. Artificial Satellite Tracking (NORAD SGP4)

AstronomyKit parses standard NORAD Two-Line Element (TLE) sets and propagates satellite orbits taking into account the Earth's oblateness ($J_2$ secular perturbation):

```swift
let issTLE = [
    "ISS (ZARYA)",
    "1 25544U 98067A   24001.50000000  .00016717  00000-0  10270-3 0  9001",
    "2 25544  51.6400 208.1000 0004500  75.3000 284.8000 15.49800000432105"
]

guard let tle = TwoLineElements.parse(lines: issTLE) else { return }
print("Satellite:", tle.name)
print("Semi-major axis:", tle.semiMajorAxisKm, "km") // ~6780 km

// Propagate position & velocity to a specific target Date
let now = Date()
let state = SatellitePropagator.propagate(tle: tle, to: now)
print("Distance from Earth center:", state.position.length, "km")

// Compute topocentric look angles (Altitude, Azimuth, Distance) for a ground observer
let look = SatellitePropagator.lookAngles(
    state: state,
    observerLatitude: 48.8566, // Paris latitude
    observerLongitude: 2.3522, // Paris longitude
    date: now
)

print("Altitude:", look.altitude, "°")
print("Azimuth:", look.azimuth, "°")
print("Distance:", look.distanceKm, "km")
```
