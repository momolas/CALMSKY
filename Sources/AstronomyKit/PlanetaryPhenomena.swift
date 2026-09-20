//
//  Planet.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 18/06/16.
//  MIT Licence. See LICENCE file.
//

import Foundation
import AAplus

func calculatePlanetaryPhenomenon(mean: Bool, jd: Double, object: KPCPlanetaryObject, type: CAAPlanetaryPhenomena.EventType) -> Double {
    let fractionalYear = CAADate(jd, true).FractionalYear()
    let planet = toPhenomenaPlanet(object)
    var runningType = type
    if object.rawValue >= KPCPlanetaryObject.KPCPlanetaryObjectMARS.rawValue {
        if type != .OPPOSITION && type != .CONJUNCTION {
            runningType = .OPPOSITION
        }
    } else {
        if type != .INFERIOR_CONJUNCTION && type != .SUPERIOR_CONJUNCTION {
            runningType = .INFERIOR_CONJUNCTION
        }
    }
    let k = CAAPlanetaryPhenomena.K(fractionalYear, planet, runningType)
    if mean {
        return CAAPlanetaryPhenomena.Mean(k.rounded(), planet, type)
    } else {
        return CAAPlanetaryPhenomena.True(k.rounded(), planet, type)
    }
}

/**
 *  The PlanetaryPhenomena protocol encompass all methods associated with planetary phenomena in the solar system:
 *  conjunction, oppotisions, etc.
 */
public protocol PlanetaryPhenomena: PlanetaryBase {
    
    /**
     Compute the julian day of the inferior conjunction of the planet after the given julian day.

     - parameter mean: The 'mean' configuration here means that it is calculated from 
     circular orbits and uniform planetary motions. See AA. pp 250.
     
     if false, the true inferior conjunction is computed. That is, calculated by adding corrections 
     to computations made from circular orbits and uniform planetary motions. See AA. pp 251.
     
     - returns: A julian day.
     */
    func inferiorConjunction(mean: Bool) -> JulianDay
    
    /**
     Compute the julian day of the superior conjunction of the planet after the given julian day.
     
     - parameter mean: The 'mean' configuration here means that it is calculated from
     circular orbits and uniform planetary motions. See AA. pp 250.
     
     if false, the true inferior conjunction is computed. That is, calculated by adding corrections
     to computations made from circular orbits and uniform planetary motions. See AA. pp 251.
     
     - returns: A julian day.
     */
    func superiorConjunction(mean: Bool) -> JulianDay
    
    func opposition(mean: Bool) -> JulianDay
    func conjunction(mean: Bool) -> JulianDay
    func easternElongation(mean: Bool) -> JulianDay
    func westernElongation(mean: Bool) -> JulianDay
    func station1(mean: Bool) -> JulianDay
    func station2(mean: Bool) -> JulianDay
    func elongationValue(eastern: Bool) -> Degree
}

public extension PlanetaryPhenomena {
    
    func inferiorConjunction(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .INFERIOR_CONJUNCTION))
    }

    func superiorConjunction(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .SUPERIOR_CONJUNCTION))
    }

    func opposition(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .OPPOSITION))
    }

    func conjunction(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .CONJUNCTION))
    }

    func easternElongation(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .EASTERN_ELONGATION))
    }

    func westernElongation(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .WESTERN_ELONGATION))
    }

    func station1(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .STATION1))
    }

    func station2(mean: Bool = true) -> JulianDay {
        return JulianDay(calculatePlanetaryPhenomenon(mean: mean, jd: self.julianDay.value, object: self.planetaryObject, type: .STATION2))
    }

    func elongationValue(eastern: Bool = true) -> Degree {
        let fractionalYear = CAADate(self.julianDay.value, true).FractionalYear()
        let planet = toPhenomenaPlanet(self.planetaryObject)
        let k = CAAPlanetaryPhenomena.K(fractionalYear, planet, .INFERIOR_CONJUNCTION)
        return Degree(CAAPlanetaryPhenomena.ElongationValue(k.rounded(), planet, eastern))
    }

}

