# Planets and Moons

Access high-precision planetary ephemerides, physical details, satellite positions, and ring systems in SwiftAA.

## Planetary Positions

To retrieve geocentric and heliocentric positions for any major planet:

```swift
import SwiftAA

let jupiter = Jupiter(julianDay: JulianDay(year: 2024, month: 11, day: 15))

// Geocentric equatorial coordinates
let equatorial = jupiter.equatorialCoordinates

// Heliocentric ecliptic coordinates
let heliocentric = jupiter.heliocentricEclipticCoordinates

// Apparent visual magnitude
let magnitude = jupiter.apparentMagnitude

// Illuminated fraction of the disk (phase)
let phase = jupiter.illuminatedFraction
```

## Galilean Moons of Jupiter

SwiftAA provides precise rectangular coordinates and eclipse details for Io, Europa, Ganymede, and Callisto:

```swift
let details = jupiter.galileanMoonsDetails()

// True / apparent rectangular coordinates (X, Y, Z in Jovian equatorial radii)
print("Io X: \(details.Moon1.X), Y: \(details.Moon1.Y)")
print("Europa X: \(details.Moon2.X), Y: \(details.Moon2.Y)")
```

## Saturn and Its Rings

```swift
let saturn = Saturn(julianDay: JulianDay(year: 2024, month: 9, day: 8))

// Saturnian ring inclinations and dimensions
let ringDetails = saturn.ringDetails()
print("Ring major axis: \(ringDetails.a), minor axis: \(ringDetails.b)")
```
