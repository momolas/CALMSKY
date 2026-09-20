//
//  CAAVSOP87.swift
//  AstronomyKit
//
//  Pure Swift implementation of VSOP87 analytical planetary series
//  accelerated by Apple Accelerate (vDSP & vForce SIMD).
//

import Foundation
import Accelerate

public enum CAAVSOP87: Sendable {

    @inlinable
    public static func calculate(jd: Double, tables: [[Double]], isAngle: Bool) -> Double {
        let t = (jd - 2451545.0) / 365250.0
        var tTerm = t
        var result = 0.0

        for (i, table) in tables.enumerated() {
            let nCoeffs = table.count / 3
            guard nCoeffs > 0 else { continue }
            var tempResult = 0.0

            if nCoeffs >= 8 {
                table.withUnsafeBufferPointer { buf in
                    guard let base = buf.baseAddress else { return }
                    let aPtr = base
                    let bPtr = base.advanced(by: 1)
                    let cPtr = base.advanced(by: 2)

                    var angles = [Double](repeating: 0, count: nCoeffs)
                    var cosines = [Double](repeating: 0, count: nCoeffs)
                    var tVal = t

                    angles.withUnsafeMutableBufferPointer { angBuf in
                        vDSP_vsmaD(cPtr, 3, &tVal, bPtr, 3, angBuf.baseAddress!, 1, vDSP_Length(nCoeffs))
                    }
                    var countInt = Int32(nCoeffs)
                    cosines.withUnsafeMutableBufferPointer { cosBuf in
                        angles.withUnsafeBufferPointer { angBuf in
                            vvcos(cosBuf.baseAddress!, angBuf.baseAddress!, &countInt)
                        }
                        vDSP_dotprD(aPtr, 3, cosBuf.baseAddress!, 1, &tempResult, vDSP_Length(nCoeffs))
                    }
                }
            } else {
                var j = 0
                while j < table.count {
                    let a = table[j]
                    let b = table[j + 1]
                    let c = table[j + 2]
                    tempResult += a * cos(b + c * t)
                    j += 3
                }
            }

            if i > 0 {
                tempResult *= tTerm
                tTerm *= t
            }
            result += tempResult
        }

        if isAngle {
            result = CAACoordinateTransformation.mapTo0To2PIRange(result)
        }
        return result
    }

    @inlinable
    public static func calculateDash(jd: Double, tables: [[Double]]) -> Double {
        let t = (jd - 2451545.0) / 365250.0
        var tTerm1 = 1.0
        var tTerm2 = t
        var result = 0.0

        for (i, table) in tables.enumerated() {
            let nCoeffs = table.count / 3
            guard nCoeffs > 0 else { continue }
            var tempPart1 = 0.0
            var tempPart2 = 0.0

            if nCoeffs >= 8 {
                table.withUnsafeBufferPointer { buf in
                    guard let base = buf.baseAddress else { return }
                    let aPtr = base
                    let bPtr = base.advanced(by: 1)
                    let cPtr = base.advanced(by: 2)

                    var angles = [Double](repeating: 0, count: nCoeffs)
                    var cosines = [Double](repeating: 0, count: nCoeffs)
                    var sines = [Double](repeating: 0, count: nCoeffs)
                    var sinC = [Double](repeating: 0, count: nCoeffs)
                    var tVal = t

                    angles.withUnsafeMutableBufferPointer { angBuf in
                        vDSP_vsmaD(cPtr, 3, &tVal, bPtr, 3, angBuf.baseAddress!, 1, vDSP_Length(nCoeffs))
                    }
                    var countInt = Int32(nCoeffs)
                    angles.withUnsafeBufferPointer { angBuf in
                        sines.withUnsafeMutableBufferPointer { sinBuf in
                            cosines.withUnsafeMutableBufferPointer { cosBuf in
                                vvsincos(sinBuf.baseAddress!, cosBuf.baseAddress!, angBuf.baseAddress!, &countInt)
                            }
                        }
                    }

                    if i > 0 {
                        cosines.withUnsafeBufferPointer { cosBuf in
                            vDSP_dotprD(aPtr, 3, cosBuf.baseAddress!, 1, &tempPart1, vDSP_Length(nCoeffs))
                        }
                        tempPart1 *= Double(i)
                    }

                    sinC.withUnsafeMutableBufferPointer { scBuf in
                        sines.withUnsafeBufferPointer { sinBuf in
                            vDSP_vmulD(sinBuf.baseAddress!, 1, cPtr, 3, scBuf.baseAddress!, 1, vDSP_Length(nCoeffs))
                        }
                        vDSP_dotprD(aPtr, 3, scBuf.baseAddress!, 1, &tempPart2, vDSP_Length(nCoeffs))
                    }
                }
            } else {
                var j = 0
                while j < table.count {
                    let a = table[j]
                    let b = table[j + 1]
                    let c = table[j + 2]
                    let b_ct = b + c * t
                    if i > 0 {
                        tempPart1 += Double(i) * a * cos(b_ct)
                    }
                    tempPart2 += a * c * sin(b_ct)
                    j += 3
                }
            }

            if i > 0 {
                tempPart1 *= tTerm1
                tempPart2 *= tTerm2
                tTerm1 *= t
                tTerm2 *= t
                result += (tempPart1 - tempPart2)
            } else {
                result -= tempPart2
            }
        }
        return result
    }

    /// Evaluates truncated Meeus series where coefficients are scaled by 10^8
    @inlinable
    public static func calculateTruncated(jd: Double, tables: [[Double]], divisor: Double = 100_000_000.0) -> Double {
        let rho = (jd - 2451545.0) / 365250.0
        var rhoPower = 1.0
        var total = 0.0

        for table in tables {
            guard !table.isEmpty else {
                rhoPower *= rho
                continue
            }
            var sum = 0.0
            var j = 0
            while j < table.count {
                let a = table[j]
                let b = table[j + 1]
                let c = table[j + 2]
                sum += a * cos(b + c * rho)
                j += 3
            }
            total += sum * rhoPower
            rhoPower *= rho
        }

        return total / divisor
    }
}
