# Predicting Crescent Moon Visibility (Hilal)

Learn how to compute Islamic crescent moon visibility parameters and evaluate standard criteria such as Odeh, Yallop, Danjon limit, Istanbul, and MABIMS.

## Overview

The first sighting of the thin lunar crescent (Hilal) after sunset marks the beginning of new months in the Islamic lunar calendar (such as Ramadan, Shawwal, and Dhul Hijjah).

SwiftAA provides a dedicated Hilal visibility module built on top of high-precision topocentric ephemerides.

## Evaluating Crescent Visibility

To evaluate the visibility of the crescent moon for a given observer location and date:

```swift
import SwiftAA

// 1. Define observer location (e.g., Mecca: 21.4225° N, 39.8262° E, 277 m)
let mecca = GeographicCoordinates(
    positivelyWestwardLongitude: Degree(-39.8262),
    latitude: Degree(21.4225),
    altitude: Meter(277)
)

// 2. Instantiate the Moon on the observation date (around sunset)
let observationJD = JulianDay(year: 2024, month: 4, day: 9, hour: 18, minute: 30, second: 0)
let moon = Moon(julianDay: observationJD)

// 3. Compute crescent visibility using the Odeh (2006) criterion
let result = moon.crescentVisibility(for: mecca, criterion: .odeh)

// 4. Inspect the results
print("Visibility Zone: \(result.zone)") 
print("Is Visible: \(result.isVisible)")
print("Elongation: \(result.elongation)")
print("Lag Time: \(result.lagTime)")
print("Best Observation Time: \(result.bestObservationTime)")
```

## Supported Criteria

### Mohammad Odeh (2006) - `.odeh`
Developed for the *Islamic Crescents' Observation Project* (ICOP) based on a database of 737 documented observations.
- **Zone A**: Easily visible to the naked eye ($V \ge 5.65$).
- **Zone B**: Visible to the naked eye under favorable atmospheric conditions ($2.00 \le V < 5.65$).
- **Zone C**: Visible only with optical aid (telescope or binoculars) ($-0.96 \le V < 2.00$).
- **Zone D**: Not visible even with optical instruments ($V < -0.96$).
- **Zone F**: Below Danjon limit ($ARCL < 7.0^\circ$).

### Bernard Yallop (1997) - `.yallop`
Standard method developed for the *HM Nautical Almanac Office* (Royal Greenwich Observatory) using the visibility parameter $q$:
- **Zone A**: Easily visible to the naked eye ($q > +0.216$).
- **Zone B**: Visible under perfect conditions ($-0.014 < q \le +0.216$).
- **Zone C**: Optical aid needed to locate, then visible to the naked eye ($-0.160 < q \le -0.014$).
- **Zone D**: Visible only with optical aid ($-0.232 < q \le -0.160$).
- **Zone D/E**: Not visible ($q \le -0.232$).

### Danjon Physical Limit - `.danjon`
The fundamental physical threshold (~7.0° elongation): below this angle, lunar surface topography shadows prevent the crescent from forming continuously.

### Istanbul Unified Criterion - `.istanbul`
Adopted by the 1978 and 2016 International Conferences:
- Arc of light (Elongation) $\ge 8.0^\circ$ at local sunset.
- Moon altitude $\ge 5.0^\circ$ at local sunset.

### MABIMS Criterion - `.mabims`
Adopted in 2021 by Brunei, Indonesia, Malaysia, and Singapore:
- Arc of light (Elongation) $\ge 6.4^\circ$ at local sunset.
- Moon altitude $\ge 3.0^\circ$ at local sunset.

## Key Parameters Extracted

A ``CrescentVisibilityResult`` provides:
- `bestObservationTime`: The optimal time of observation ($T_{\text{sunset}} + \frac{4}{9}(T_{\text{moonset}} - T_{\text{sunset}})$).
- `lagTime`: Duration between local sunset and moonset.
- `elongation` ($ARCL$): Topocentric angular separation between the center of the Sun and Moon.
- `arcOfVision` ($ARCV$): Topocentric altitude difference ($h_{\text{moon}} - h_{\text{sun}}$).
- `differenceInAzimuth` ($DAZ$): Azimuth difference ($|Az_{\text{moon}} - Az_{\text{sun}}|$).
- `crescentWidth` ($W$): Topocentric crescent width in arcminutes.
- `moonAge`: Elapsed time since geocentric new moon conjunction.
