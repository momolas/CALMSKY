//
//  RiseTransitSet.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 17/12/2016.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// The RiseTransitSetTimesDetails struct encompasses all elements of the times of rise, transit and set.
public struct RiseTransitSetTimesDetails: Sendable {
    public private(set) var isRiseValid: Bool
    public private(set) var riseTime: JulianDay
    public private(set) var isTransitValid: Bool
    public private(set) var isTransitAboveHorizon: Bool
    public private(set) var transitTime: JulianDay
    public private(set) var isSetValid: Bool
    public private(set) var setTime: JulianDay
}


/// Calculate the rise, transit and set times of a celestial body for a given
/// location on Earth.
/// 
/// One must correct the instants of the geometric rise and set of the center
/// of the celestial body by the athomspheric refraction. Because of it, the
/// body is actually below the horizon at the instant of its apparent rise or set.
/// The value of 0º34' is generally adopted for the effect of refraction
/// at the horizon. For the Sun, the calculated times generally refer to the 
/// apparent rise or set of the upper limb of the disk, hence, 0º16'
/// should be added to the semidiameter
///
/// Actually, the amount of refraction changes with air temperature, pressure and
/// the elevation of the observer. A change of temperature from winter to summer
/// can shift the times of sunrise and sunset by about 20 secondes in mid-northern
/// and mid-southern latitudes. Similarly, observing sunrise or sunset over
/// a range of barometric pressures leads to a variation of a dozen seconds in the
/// times. However, in this chapter we shall use a mean value of the atmospheric
/// refraction at the horizon, namely the value of 0º34' mentionned above.
///
/// Notes:
/// The geographic longitude must be expressed postively west from Greenwhich,
/// in degrees.
/// The standard altitude, i.e. the geometric altitude of the center of the body
/// at the time of apparent rising, setting, namely:
/// h0 = -0º34' = 0º.5667 for stars and planets
/// h0 = -0º50' = 0º.8333 for the sun
/// h0 = +0º.125 for the moon
/// Actually, for the moon h0 is not constant. See p.102 of AA.
///
/// - Parameters:
///   - julianDay: the date at which one want to compute the times. MUST BE SET AT 0h UT for the given DAY.
///   - equCoords1: the equatorial coordinates of the body at Date - 1 Day.
///   - equCoords2: the equatorial coordinates of the body at Date.
///   - equCoords3: the equatorial coordinates of the body at Date + 1 Day.
///   - geoCoords: the location on Earth, with its altitude set to the standard one (see above)
/// - Returns: the times of rise, transit and set, with an indication if it is actually valid or not.
public func riseTransitSet(forJulianDay julianDay: JulianDay,
                           equCoords1: EquatorialCoordinates,
                           equCoords2: EquatorialCoordinates,
                           equCoords3: EquatorialCoordinates,
                           geoCoords: GeographicCoordinates,
                           apparentRiseSetAltitude: Degree) -> RiseTransitSetTimesDetails
{
    // Do NOT pass Right Ascension values in degrees, as requested by AA+. It will be transformed later.
    // See CAARiseTransitSet::CalculateTransit, line 72.
    let details = CAARiseTransitSet.Calculate(julianDay.value,
                                              equCoords1.alpha.value,
                                              equCoords1.delta.value,
                                              equCoords2.alpha.value,
                                              equCoords2.delta.value,
                                              equCoords3.alpha.value,
                                              equCoords3.delta.value,
                                              geoCoords.longitude.value,
                                              geoCoords.latitude.value,
                                              apparentRiseSetAltitude.value)
    
    let rise = julianDay + Hour(details.Rise).inJulianDays
    let transit = julianDay + Hour(details.Transit).inJulianDays
    let set = julianDay + Hour(details.Set).inJulianDays
    
    return RiseTransitSetTimesDetails(isRiseValid: details.bRiseValid,
                                      riseTime: rise,
                                      isTransitValid: details.bTransitValid,
                                      isTransitAboveHorizon: details.bTransitAboveHorizon,
                                      transitTime: transit,
                                      isSetValid: details.bSetValid,
                                      setTime: set)
}


/// Convenient class for storing the Rise, Transit and Set times of a celestial body.
public struct RiseTransitSetTimes: Sendable {
    @usableFromInline internal var details: RiseTransitSetTimesDetails? = nil
    public fileprivate(set) var transitError: CelestialBodyTransitError? = nil
    public fileprivate(set) var geographicCoordinates: GeographicCoordinates
    public fileprivate(set) var riseSetAltitude: Degree
    
    
    /// Returns a new RiseTransitSetTimes object giving access to Rise, Transit and Set times of the provided body.
    ///
    /// - Parameters:
    ///   - celestialBody: The celestial body under study.
    ///   - geographicCoordinates: The geographic coordinates of the observer.
    ///   - riseSetAltitude: The altitude considered for rise and set times.
    ///   - highPrecision: If `true`, solves continuously using vector topocentric horizon detection,
    ///                    observer elevation dip, and Brent numerical root-finding (< 0.1s error).
    ///                    If `false`, uses the classical Meeus Ch. 15 3-point parabolic interpolation.
    public init(
        celestialBody: CelestialBody,
        geographicCoordinates: GeographicCoordinates,
        riseSetAltitude: Degree? = nil,
        highPrecision: Bool = false
    ) {
        self.geographicCoordinates = geographicCoordinates
        self.riseSetAltitude = riseSetAltitude ?? type(of: celestialBody).apparentRiseSetAltitude

        if highPrecision {
            let nominalAltitude = self.riseSetAltitude
            let targetAlt = TopocentricHorizonEngine.targetRiseSetAltitude(
                standardAltitudeDeg: nominalAltitude.value,
                altitudeMeters: geographicCoordinates.altitude.value
            )

            let jdMidnight = celestialBody.julianDay.midnight.value
            let hp = celestialBody.highPrecision
            let bodyType = type(of: celestialBody)

            let altitudeAt: (Double) -> Double
            if let obj = celestialBody as? AstronomicalObject {
                let observer = TopocentricHorizonEngine.FixedEquatorialObserver(
                    alphaHours: obj.equatorialCoordinates.alpha.value,
                    deltaDeg: obj.equatorialCoordinates.delta.value,
                    geoCoords: geographicCoordinates
                )
                altitudeAt = { t in
                    observer.altitude(at: t)
                }
            } else {
                let rho = GlobeEngine.rhoCoordinates(
                    latitude: geographicCoordinates.latitude.value,
                    height: geographicCoordinates.altitude.value
                )
                let lon = geographicCoordinates.longitude.value
                let lat = geographicCoordinates.latitude.value
                altitudeAt = { t in
                    let inst = bodyType.init(julianDay: JulianDay(t), highPrecision: hp)
                    let topoEqu = inst.equatorialCoordinates
                    let coords = CAAParallax.equatorialToTopocentric(
                        alphaHours: topoEqu.alpha.value,
                        deltaDeg: topoEqu.delta.value,
                        distanceAU: inst.radiusVector.value,
                        longitudeDeg: lon,
                        rhoSin: rho.rhoSin,
                        rhoCos: rho.rhoCos,
                        jd: t
                    )
                    let siderealDeg = CAASidereal.apparentGreenwichSiderealTime(t) * 15.0 - lon
                    let hourAngleHours = (siderealDeg - coords.X * 15.0) / 15.0
                    let horiz = CAACoordinateTransformation.equatorial2Horizontal(
                        alpha: hourAngleHours,
                        delta: coords.Y,
                        latitude: lat
                    )
                    return horiz.y
                }
            }

            let result = TopocentricHorizonEngine.solve(
                centerJD: jdMidnight,
                targetAltitudeDeg: targetAlt,
                altitudeAt: altitudeAt
            )

            let rise = result.riseJD.map { JulianDay($0) } ?? JulianDay(0)
            let transit = result.transitJD.map { JulianDay($0) } ?? JulianDay(0)
            let set = result.setJD.map { JulianDay($0) } ?? JulianDay(0)

            self.details = RiseTransitSetTimesDetails(
                isRiseValid: result.isRiseValid,
                riseTime: rise,
                isTransitValid: result.isTransitValid,
                isTransitAboveHorizon: result.maxAltitudeDeg > targetAlt,
                transitTime: transit,
                isSetValid: result.isSetValid,
                setTime: set
            )

            if result.isCircumpolarAbove {
                self.transitError = .alwaysAboveAltitude
            } else if result.isCircumpolarBelow {
                self.transitError = .alwaysBelowAltitude
            }
            return
        }

        // AA+ p.102 indicates one need to get day D at 0h Dynamical Time, thus, midnight UT.
        let jd = celestialBody.julianDay.midnight
        let hp = celestialBody.highPrecision

        let celestialBodyType = type(of: celestialBody)
        if (celestialBodyType is AstronomicalObject.Type) {
            self.details = riseTransitSet(forJulianDay: jd,
                                          equCoords1: celestialBody.equatorialCoordinates,
                                          equCoords2: celestialBody.equatorialCoordinates,
                                          equCoords3: celestialBody.equatorialCoordinates,
                                          geoCoords: geographicCoordinates,
                                          apparentRiseSetAltitude: AstronomicalObject.apparentRiseSetAltitude)

        } else {
            let body1: CelestialBody = celestialBodyType.init(julianDay: jd-1, highPrecision: hp)
            let body2: CelestialBody = celestialBodyType.init(julianDay: jd, highPrecision: hp)
            let body3: CelestialBody = celestialBodyType.init(julianDay: jd+1, highPrecision: hp)

            self.details = riseTransitSet(forJulianDay: jd,
                                          equCoords1: body1.equatorialCoordinates,
                                          equCoords2: body2.equatorialCoordinates,
                                          equCoords3: body3.equatorialCoordinates,
                                          geoCoords: self.geographicCoordinates,
                                          apparentRiseSetAltitude: self.riseSetAltitude)

        }

        if let details = self.details, !details.isRiseValid, !details.isSetValid {
            self.transitError = details.isTransitAboveHorizon ? .alwaysAboveAltitude : .alwaysBelowAltitude
        }
    }
        

    /// Returns a new RiseTransitSetTimes object with an error.
    ///
    /// - Parameters:
    ///   - geographicCoordinates: The geographic coordinates of the observer.
    ///   - riseSetAltitude: The altitude considered for rise and set times.
    public init(geographicCoordinates: GeographicCoordinates, transitError: CelestialBodyTransitError? = nil)
    {
        self.transitError = transitError
        self.geographicCoordinates = geographicCoordinates
        self.riseSetAltitude = Degree(0)
    }
    
    /// The rise time of the celestial body, in Julian Day.
    @inlinable
    public var riseTime: JulianDay? {
        guard let details = self.details, details.isRiseValid else { return nil }
        return details.riseTime
    }
    
    /// The transit time of the celestial body, in Julian Day.
    @inlinable
    public var transitTime: JulianDay? {
        guard let details = self.details, details.isTransitValid else { return nil }
        return details.transitTime
    }
    
    /// The set time of the celestial body, in Julian Day.
    @inlinable
    public var setTime: JulianDay? {
        guard let details = self.details, details.isSetValid else { return nil }
        return details.setTime
    }
}



