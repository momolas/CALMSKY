# ``AstronomyKit``

The most comprehensive collection of accurate astronomical algorithms in Swift.

## Overview

**AstronomyKit** provides modern, expressive, and type-safe Swift APIs for astronomical calculations, ephemerides, celestial mechanics, and observational astronomy.

Built upon the reference C++ engine **AA+** (by PJ Naughter) implementing the algorithms of **Jean Meeus** (*Astronomical Algorithms*, 2nd ed.), along with the **VSOP87** planetary theory and **ELP/MPP02** lunar theory, AstronomyKit provides professional-grade accuracy with the safety and elegance of modern Swift.

### Key Features

- **Unit Safety & Numerical Types**: Strongly-typed angles ([`Degree`](doc:Degree), [`Radian`](doc:Radian), [`ArcSecond`](doc:ArcSecond)), times ([`Hour`](doc:Hour), [`Minute`](doc:Minute), [`Second`](doc:Second), [`JulianDay`](doc:JulianDay)), and distances ([`AstronomicalUnit`](doc:AstronomicalUnit), [`Kilometer`](doc:Kilometer)).
- **Coordinate Systems & Reductions**: Geocentric and topocentric equatorial, ecliptic, horizontal, and galactic coordinates with corrections for precession, nutation, aberration, atmospheric refraction, and diurnal parallax.
- **Solar System & Celestial Bodies**: High-precision ephemerides for the [Sun](doc:Sun), [Moon](doc:Moon), Earth, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, and asteroids.
- **Moons & Planetary Details**: Galilean moons of Jupiter, moons and rings of Saturn, planetary physical details, illuminated fractions, and magnitudes.
- **Events & Phenomena**: Rise, transit, and set times, twilights, seasons, equinoxes, solstices, eclipses, conjunctions, and oppositions.
- **Hilal & Crescent Visibility**: Islamic crescent moon visibility predictions using Odeh (2006), Yallop (1997), Danjon limit, Istanbul, and MABIMS criteria.
- **Meteor Showers**: Catalog of major annual showers with radiant coordinates, peak times, and lunar interference ratings.
- **SwiftUI & Modern Formatting**: Native SwiftUI `Angle` conversions, `FormatStyle` sexagesimal and right ascension formatting.

## Topics

### Getting Started & Guides

- <doc:HilalVisibility>
- <doc:CoordinatesAndTransformations>
- <doc:StandardsAndReductions>
- <doc:RiseTransitSetTimes>
- <doc:PlanetsAndMoons>

### Global Standards & Vector Astrometry

- ``Vector3D``
- ``StateVector``
- ``AstrometryReductions``
- ``AstronomicalTimeScale``
- ``ModernReferenceFrames``

### Artificial Satellite Tracking (SGP4)

- ``TwoLineElements``
- ``SatellitePropagator``

### Modern Value-Type Ephemerides

- ``SolarSystemBody``
- ``EphemerisSnapshot``

### Celestial Bodies

- ``Sun``
- ``Moon``
- ``Earth``
- ``Mars``
- ``Jupiter``
- ``Saturn``
- ``Venus``
- ``Mercury``
- ``Uranus``
- ``Neptune``
- ``Pluto``

### Moon Phases & Quarters

- ``LunarPhase``
- ``MoonPhase``
- ``MoonPhaseEvent``

### Meteor Showers

- ``MeteorShower``
- ``MeteorObservationRating``

### Crescent Visibility (Hilal)

- ``CrescentVisibilityCriterion``
- ``CrescentVisibilityZone``
- ``CrescentVisibilityResult``

### Coordinates & Reference Frames

- ``EquatorialCoordinates``
- ``HorizontalCoordinates``
- ``EclipticCoordinates``
- ``GalacticCoordinates``
- ``GeographicCoordinates``
- ``ProperMotion``
- ``Epoch``
- ``Equinox``

### Ephemerides & Phenomena

- ``RiseTransitSetTimes``
- ``RiseTransitSetTimesDetails``
- ``CelestialBodyTransitError``
- ``Season``

### Formatting & Interoperability

- ``SexagesimalFormatStyle``
- ``RightAscensionFormatStyle``

### Numerical & Unit Types

- ``JulianDay``
- ``Degree``
- ``Radian``
- ``ArcMinute``
- ``ArcSecond``
- ``Hour``
- ``Minute``
- ``Second``
- ``Day``
- ``AstronomicalUnit``
- ``Kilometer``
- ``Meter``
- ``Magnitude``
- ``NumericType``
