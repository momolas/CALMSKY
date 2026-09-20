# AstronomyKit

![](https://img.shields.io/badge/Swift-6.0%20%7C%206.2-blue.svg?style=flat)
![](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20watchos%20%7C%20tvos%20%7C%20visionos%20%7C%20linux-lightgrey.svg)
![](https://img.shields.io/badge/licence-MIT-blue.svg)

*The most comprehensive collection of accurate astronomical algorithms in modern Swift.* 

Description
===========

**AstronomyKit** provides everything you need to compute planetary orbits, solar & lunar eclipses, length of seasons, moon phases, rise/transit/set times, Galilean moons of Jupiter, Saturn's rings, coordinate transformations, religious & lunisolar calendars (Hijri, Jewish, Easter), crescent visibility (*Hilal*), atmospheric air mass, and observation windows with professional-grade accuracy.

In addition to classical analytical models (Meeus, VSOP87, ELP2000), AstronomyKit incorporates the core algorithms of **international reference standards**:
- **USNO NOVAS** : 3D Cartesian vector astrometry (`Vector3D`, `StateVector`), Einstein gravitational light deflection, and relativistic stellar aberration.
- **IAU SOFA** : Modern time scales (`UT1`, `UTC`, `TAI`, `TT`, `TDB`), $\Delta T$ (Espenak & Meeus 2006), Earth Rotation Angle (ERA IAU 2000), and CIRS $\leftrightarrow$ TIRS coordinate rotations.
- **NORAD SGP4** : Artificial satellite orbit propagation from standard Two-Line Element (TLE) sets, with topocentric observer look angles (altitude, azimuth, distance).

### Architecture & Direct C++ Interoperability

AstronomyKit directly leverages **Swift C++ Interoperability (`.interoperabilityMode(.Cxx)`)** atop **AA+ v2.63**, the C++ implementation by P.J. Naughter of the reference textbook *Astronomical Algorithms* by Jean Meeus (2nd ed.). 

- **Zero-cost bridge**: Direct C++ calls with zero runtime wrapper overhead.
- **Swift 6 & Strict Concurrency ready**: 100% data-race safe, pure `Sendable` value types across astronomical objects, coordinates, and events.
- **Autonomous & Zero External Dependencies**: Runs entirely offline without external kernels, binary files, or network calls.
- **Strong Unit Safety**: Type-safe dimensional structures for `Degree`, `ArcSecond`, `Hour`, `JulianDay`, `AstronomicalUnit`, `Kilometer`, etc.
- **High Test Coverage**: Over 238 unit tests combining `XCTest` and modern `Swift-Testing` (`@Test`, `@Suite`).

---

Features & Examples
===================

### 1. Planets & Solar System Bodies

```swift
import AstronomyKit

// Target date: standard J2000 epoch
let jd = JulianDay(year: 2024, month: 4, day: 8, hour: 18, minute: 17)

// Earth & Seasons
let earth = Earth(julianDay: jd)
let springLength = earth.lengthOfSeason(.spring, northernHemisphere: true) // 92.75 days

// Mars Physical & Apparent Coordinates
let mars = Mars(julianDay: jd)
let equatorial = mars.apparentEquatorialCoordinates
let phase = mars.phaseAngle()
let dist = mars.radiusVector // Distance to Sun in AU

// Moon & Phases
let moon = Moon(julianDay: jd)
let illFraction = moon.illuminatedFraction()
```

### 2. Solar & Lunar Eclipses

```swift
// Predict characteristics of a Solar Eclipse (k = lunation index)
let solarEclipse = Eclipses.calculateSolar(k: -82.0)
print(solarEclipse.isPartial) // true
print(solarEclipse.greatestMagnitude) // 0.735

// Predict characteristics of a Lunar Eclipse
let lunarEclipse = Eclipses.calculateLunar(k: -328.5)
print(lunarEclipse.hasEclipse) // true
print(lunarEclipse.umbralMagnitude)
```

### 3. Religious & Lunisolar Calendars

```swift
// Islamic / Hijri Calendar
let hijri = HijriDate(year: 1445, month: 9, day: 1) // Ramadan 1, 1445 AH
let gregorianDate = hijri.toGregorianCalendarDate()
print(hijri.isLeapYear)

// Hebrew / Jewish Calendar
let pesach = JewishDate.dateOfPesach(civilYear: 2024) // 15 Nisan
let isJewishLeap = JewishDate(year: 5784, month: 1, day: 1).isLeapYear

// Easter Sunday
let westernEaster = Easter.calculate(year: 2026, inGregorianCalendar: true)
let orthodoxEaster = Easter.calculate(year: 2026, inGregorianCalendar: false)
```

### 4. Lunar Standstills (Lunistices)

```swift
// Compute extreme Moon declination dates and values
let standstill = Moon.greatestDeclination(nearYear: 2024.5, northerly: true)
print(standstill.declination.formatted(.sexagesimal)) // "> +28°"
```

### 5. Comets & Parabolic Orbits

```swift
let elements = ParabolicOrbitElements(
    perihelionDistance: 1.324558.AU,
    inclination: 22.4111.degrees,
    argumentOfPerihelion: 130.6013.degrees,
    longitudeOfAscendingNode: 12.4403.degrees,
    jdEquinox: JulianDay(2447891.5),
    timeOfPerihelion: JulianDay(2447810.0)
)

let cometDetails = ParabolicOrbit.calculate(julianDay: JulianDay(2447891.5), elements: elements)
print(cometDetails.astrometricRightAscension.formatted(.rightAscension))
```

### 6. Atmospheric Air Mass & Observation Window

```swift
// Pickering (2002) optical air mass
let airMass = AtmosphericAirMass.pickeringAirMass(trueAltitude: 45.0.degrees)

// Assess night observability for telescope targeting
let observer = GeographicCoordinates(eastLongitude: 2.35.degrees, latitude: 48.85.degrees)
let horizontal = HorizontalCoordinates(azimuth: 180.0.degrees, altitude: 45.0.degrees, geographicCoordinates: observer, julianDay: jd)

let window = horizontal.observationWindow(sunAltitude: -20.0.degrees, minTargetAltitude: 30.0.degrees)
print(window.isOptimal) // true (target > 30° during dark night)
```

### 7. Modern Formatting & Foundation Interoperability

```swift
// Sexagesimal & Right Ascension FormatStyles
let dec = Degree(-15.4321)
dec.formatted(.sexagesimal) // "-15° 25' 55.56\""

let ra = Hour(12.5891)
ra.formatted(.rightAscension) // "12h 35m 20.76s"

// Foundation Measurement bridging
let mAngle: Measurement<UnitAngle> = 45.0.degrees.measurement
let mLength: Measurement<UnitLength> = 1.0.AU.measurement
```

### 8. Value-Type Solar System Ephemerides

```swift
// Fast, immutable, Sendable snapshot of any body
let snapshot = SolarSystemBody.mars.ephemeris(at: jd)
print(snapshot.body.symbol) // "♂"
print(snapshot.apparentMagnitude) // -1.2
print(snapshot.radiusVector) // Distance to Sun in AU

// Instant access to all bodies for UI lists & SwiftUI Pickers
for body in SolarSystemBody.allCases {
    let ephem = body.ephemeris(at: jd)
    print("\(body.symbol) \(body.name): \(ephem.radiusVector)")
}
```

### 9. Moon Phases & Exact Quarters

```swift
// 8-Phase classification (🌑, 🌒, 🌓, 🌔, 🌕, 🌖, 🌗, 🌘)
let currentPhase = moon.lunarPhase
print(currentPhase.symbol) // e.g. "🌔"
print(currentPhase.name)   // "Waxing Gibbous"
print(currentPhase.isWaxing) // true

// Predict exact Julian Day of the next Full Moon or New Moon
let nextFullMoon = Moon.nextPhase(.fullMoon, after: jd)
print("Next Full Moon:", nextFullMoon.date)

// List all quarters within a date range
let nextMonth = jd + 30
let events = Moon.phases(from: jd, to: nextMonth)
for event in events {
    print("\(event.phase.symbol) \(event.phase.name) on \(event.julianDay.date)")
}
```

### 10. Universal Angular Separation & Conjunctions

```swift
let venus = Venus(julianDay: jd)
let jupiter = Jupiter(julianDay: jd)

// Measure apparent sky separation between any two celestial bodies
let sep = venus.angularSeparation(from: jupiter)
let posAngle = venus.positionAngle(relativeTo: jupiter)
print("Separation: \(sep.formatted(.sexagesimal))")
```

### 11. Annual Meteor Showers Catalog

```swift
let perseids = MeteorShower.perseids
print("Perseids peak:", perseids.peakMonth, "/", perseids.peakDay)
print("ZHR:", perseids.zhr) // 100 meteors/hour
print("Parent:", perseids.parentBody) // "109P/Swift-Tuttle"

// Evaluate moonlight interference for a specific year
let rating = perseids.observationRating(year: 2026)
print(rating.description) // e.g. "Favorable (Dark skies, minimal moonlight)"
```

### 12. Native SwiftUI Integration

```swift
#if canImport(SwiftUI)
import SwiftUI

// Seamless SwiftUI Angle conversion
let heading: SwiftUI.Angle = 45.0.degrees.asSwiftUIAngle
let reconstructedDeg = Degree(heading)

// Declarative Text formatting in views
struct AstronomyView: View {
    let moonDeclination = Degree(-23.44)

    var body: some View {
        VStack {
            Text(moonDeclination, format: .sexagesimal)
            Text(Hour(14.5), format: .rightAscension)
        }
    }
}
#endif
```

### 13. Vector Astrometry & Relativistic Deflection (USNO NOVAS)

```swift
// 3D Cartesian coordinates with full vector arithmetic
let starDirection = Vector3D.fromSpherical(ra: 45.0, dec: 30.0, distance: 1.0)
let earthPos = Vector3D(x: 1.0, y: 0.0, z: 0.0) // 1 AU from Sun

// Einstein gravitational light deflection near the Sun
let deflected = AstrometryReductions.gravitationalDeflection(bodyPos: starDirection, earthPos: earthPos)

// Relativistic stellar aberration
let earthVelocity = Vector3D(x: 0.0, y: 0.0172, z: 0.0) // AU/day
let apparent = AstrometryReductions.aberration(direction: starDirection, observerVelocity: earthVelocity)
```

### 14. Modern Reference Frames & Time Scales (IAU SOFA)

```swift
let jdUTC = 2451545.0 // J2000.0

// Compute Delta T (TT - UT1) and convert UTC to Terrestrial Time (TT)
let deltaTSeconds = AstronomicalTimeScale.deltaT(for: jdUTC) // ~64.09s
let jdTT = AstronomicalTimeScale.utcToTT(jdUTC: jdUTC)

// Earth Rotation Angle (ERA IAU 2000)
let era = ModernReferenceFrames.earthRotationAngleDegrees(jdUT1: jdUTC)

// CIRS to TIRS intermediate frame rotation
let cirsVector = Vector3D(x: 1.0, y: 0.0, z: 0.0)
let tirsVector = ModernReferenceFrames.cirsToTirs(cirsVector: cirsVector, jdUT1: jdUTC)
```

### 15. Satellite Tracking & TLE (NORAD SGP4)

```swift
let issTLE = [
    "ISS (ZARYA)",
    "1 25544U 98067A   24001.50000000  .00016717  00000-0  10270-3 0  9001",
    "2 25544  51.6400 208.1000 0004500  75.3000 284.8000 15.49800000432105"
]

guard let tle = TwoLineElements.parse(lines: issTLE) else { return }
print("Semi-major axis:", tle.semiMajorAxisKm, "km")

// Propagate orbit to current date
let now = Date()
let state = SatellitePropagator.propagate(tle: tle, to: now)

// Compute topocentric look angles for ground observer
let look = SatellitePropagator.lookAngles(
    state: state,
    observerLatitude: 48.8566, // Paris
    observerLongitude: 2.3522,
    date: now
)
print("Altitude: \(look.altitude)°, Azimuth: \(look.azimuth)°, Range: \(look.distanceKm) km")
```

---

Documentation
=============

AstronomyKit includes full **Apple DocC** documentation. You can preview it in your browser with:

```bash
swift package --disable-sandbox preview-documentation --target AstronomyKit
```

Or build the documentation in Xcode via **Product > Build Documentation**.

---

Installation
============

Add AstronomyKit as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/momolas/AstronomyKit.git", branch: "master")
]
```

Or add it directly in Xcode via **File > Add Package Dependencies...** with `https://github.com/momolas/AstronomyKit.git`.

---

AA+ Core
========

The AA+ framework, written in C++ by PJ Naughter (Visual C++ MVP), is the comprehensive implementation of the algorithms in Jean Meeus' reference textbook *Astronomical Algorithms*. 

AstronomyKit integrates **AA+ v2.63** (released May 2025) directly as a C++ SPM module target (`AAplus`).

---

Caution on Coordinates
======================

Coordinates computations are key for modern astronomy. Note that classical Meeus algorithms are referenced to standard dynamical epochs (such as standard equinox FK5 J2000.0) rather than relativistic ICRS. For conversions requiring high-order relativistic stellar motions, refer also to packages like [AstroPy](http://docs.astropy.org/en/stable/coordinates/index.html).

---

Author
======

Cédric Foellmi, a.k.a. **[@onekiloparsec](https://twitter.com/onekiloparsec)** ([website](https://onekiloparsec.dev)). <br/>
(Ph.D. in astrophysics, and former *support astronomer* at the [European Southern Observatory](http://www.eso.org) in Chile). <br/> Author of the app iObserve for macOS and [arcsecond.io](https://www.arcsecond.io).

---

Licence
=======

The licence of this software is the [MIT](http://opensource.org/licenses/MIT) licence. The underlying AA+ Framework retains its own licence by PJ Naughter:

* You are allowed to include the source code in any product (commercial, shareware, freeware or otherwise) when your product is released in binary form.
* You are allowed to modify the source code in any way you want except you cannot modify the copyright details at the top of each module.
* If you want to distribute source code with your application, then you are only allowed to distribute versions released by the author.
