# Rise, Transit, and Set Times

Learn how to compute rising, meridian transit, setting times, and twilights for celestial bodies.

## Computing Rise, Transit, and Set

Every celestial body conforming to `CelestialBody` (Sun, Moon, Planets) can calculate its rise, transit, and set times for a given location on Earth:

```swift
import SwiftAA

let paris = GeographicCoordinates(
    positivelyWestwardLongitude: Degree(-2.3522),
    latitude: Degree(48.8566),
    altitude: Meter(35)
)

let sun = Sun(julianDay: JulianDay(year: 2024, month: 6, day: 21))
let times = sun.riseTransitSetTimes(for: paris)

if let sunrise = times.riseTime {
    print("Sunrise: \(sunrise.date)")
}

if let transit = times.transitTime {
    print("Solar Noon / Transit: \(transit.date)")
}

if let sunset = times.setTime {
    print("Sunset: \(sunset.date)")
}
```

## Twilights

You can compute civil, nautical, and astronomical twilights using ``Earth``:

```swift
let earth = Earth(julianDay: JulianDay(year: 2024, month: 6, day: 21))

// Astronomical twilight (-18° altitude)
let twilightTimes = earth.twilights(
    forSunAltitude: TwilightSunAltitude.astronomical.rawValue,
    coordinates: paris
)

print("Astronomical dawn: \(twilightTimes.riseTime?.date ?? Date())")
print("Astronomical dusk: \(twilightTimes.setTime?.date ?? Date())")
```
