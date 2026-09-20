# Coordinates and Coordinate Systems

Understand how to represent, convert, and correct celestial coordinates in SwiftAA.

## Coordinate Systems

SwiftAA provides strongly-typed structs for all major celestial coordinate frames:

- ``EquatorialCoordinates``: Right Ascension ($\alpha$) and Declination ($\delta$), referenced to the Earth's equator and equinox.
- ``HorizontalCoordinates``: Azimuth ($A$) and Altitude ($h$), referenced to the local horizon of the observer.
- ``EclipticCoordinates``: Celestial Longitude ($\lambda$) and Celestial Latitude ($\beta$), referenced to the plane of the Earth's orbit.
- ``GalacticCoordinates``: Galactic Longitude ($l$) and Galactic Latitude ($b$), referenced to the Milky Way galactic plane.

## Transforming Coordinates

### Equatorial to Horizontal (Local Sky)

To compute the local altitude and azimuth of an object:

```swift
let equatorial = EquatorialCoordinates(
    rightAscension: Hour(5, 55, 10.3),
    declination: Degree(7, 24, 25.4)
)

let observer = GeographicCoordinates(
    positivelyWestwardLongitude: Degree(-2.3522),
    latitude: Degree(48.8566),
    altitude: Meter(35)
)

let horizontal = equatorial.makeHorizontalCoordinates(for: observer, at: JulianDay(year: 2024, month: 1, day: 15))
print("Altitude: \(horizontal.altitude), Azimuth: \(horizontal.azimuth)")
```

### Topocentric Positions (Corrected for Parallax)

Because the Moon is near Earth, its position shifts significantly depending on observer location on the globe (diurnal parallax).

You can compute direct topocentric coordinates on ``Moon`` and ``Sun``:

```swift
let moon = Moon(julianDay: JulianDay(year: 2024, month: 4, day: 8))

// Topocentric equatorial coordinates (α, δ)
let topoEquatorial = moon.topocentricEquatorialCoordinates(for: observer)

// Topocentric horizontal coordinates (Azimuth, Altitude)
let topoHorizontal = moon.topocentricHorizontalCoordinates(for: observer)
```

## Precession, Nutation, and Aberration

```swift
// Precess coordinates to a different equinox
let precessed = equatorial.precessedCoordinates(to: .standardB1950)

// Angular separation between two points
let sep = coordA.angularSeparation(with: coordB)
```
