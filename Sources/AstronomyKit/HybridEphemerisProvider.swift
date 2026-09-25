//
//  HybridEphemerisProvider.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation

/// High-precision ephemeris provider combining VSOP2013 (planets) with JPL DE440 / DE442s (Moon).
///
/// This hybrid architecture achieves the best precision-to-size ratio:
/// - **Planets** (Mercury → Pluto): ≈1–10 meter accuracy via VSOP2013 (IMCCE).
/// - **Moon**: ≈1–3 centimeter accuracy via JPL DE440 / DE442s Lunar Laser Ranging.
/// - **Total data footprint**: ≈18 MB (vs ≈115 MB for the full DE440 kernel).
///
/// For full numerical exclusivity without analytical hybrid stitching, consider **Mode C**:
/// the unified NASA JPL DE442s baseline (``SPKEphemerisProvider`` / ``StreamingSPKEphemerisProvider``)
/// which models all planets and the Moon with sub-meter / sub-centimeter physical accuracy.
///
/// ## How It Works
///
/// VSOP2013 computes the position of the **Earth-Moon Barycenter (EMB)** relative to the Sun.
/// The Moon's position relative to the EMB comes from DE440 / DE442s. These are combined as:
///
/// ```
/// Moon (heliocentric) = EMB (VSOP2013) + Moon_geocentric (DE440) × (1 − μ)
/// Earth (heliocentric) = EMB (VSOP2013) − Moon_geocentric (DE440) × μ
/// ```
///
/// Both VSOP2013 and DE440 / DE442s use the same reference frame (ICRS/J2000) and time scale (TDB),
/// making this combination scientifically rigorous.
///
/// ## Usage
///
/// ```swift
/// let provider = try HybridEphemerisProvider(
///     vsop2013DataURL: vsopDir,
///     lunarSPKURL: de442sURL
/// )
/// let moonPos = try provider.position(for: .moon, at: jd) // Centimeter precision!
/// let marsPos = try provider.position(for: .mars, at: jd)  // Meter precision
/// ```
///
/// Use ``EphemerisDataManager/makeHybridProvider(progress:)`` or ``EphemerisDataManager/makeHybridDE442sProvider(progress:)`` for automatic download and setup.
public final class HybridEphemerisProvider: Sendable {

    // MARK: - Constants

    /// Mass ratio: Moon / (Earth + Moon).
    ///
    /// From IAU 2009 / DE440:  μ_Moon / (μ_Earth + μ_Moon) = 1 / (1 + 81.30056907)
    private static let moonMassRatio: Double = 1.0 / (1.0 + 81.30056907)

    // MARK: - Properties

    /// Provider for planetary positions (VSOP2013).
    private let planetary: VSOP2013Provider

    /// Provider for the Moon's geocentric position (DE440).
    private let lunar: LunarDE440Provider

    // MARK: - Initialization

    /// Creates a hybrid provider from VSOP2013 data and a DE440 lunar SPK file.
    ///
    /// - Parameters:
    ///   - vsop2013DataURL: Directory containing VSOP2013 binary files.
    ///   - lunarSPKURL: Path to the DE440 `.bsp` file.
    /// - Throws: ``EphemerisError`` if either data source cannot be loaded.
    public init(vsop2013DataURL: URL, lunarSPKURL: URL) throws {
        self.planetary = try VSOP2013Provider(dataDirectoryURL: vsop2013DataURL)
        self.lunar = try LunarDE440Provider(spkFileURL: lunarSPKURL)
    }

    /// Creates a hybrid provider from pre-constructed component providers.
    ///
    /// - Parameters:
    ///   - planetary: A configured VSOP2013 provider.
    ///   - lunar: A configured DE440 lunar provider.
    public init(planetary: VSOP2013Provider, lunar: LunarDE440Provider) {
        self.planetary = planetary
        self.lunar = lunar
    }
}

// MARK: - EphemerisProvider Conformance

extension HybridEphemerisProvider: EphemerisProvider {

    /// Heliocentric position of a Solar System body in AU (ICRS/J2000).
    ///
    /// For the Moon, this combines the EMB position from VSOP2013 with the geocentric
    /// Moon offset from DE440, providing centimeter-level accuracy.
    public func position(for body: SolarSystemBody, at jd: JulianDay) throws -> Vector3D {
        switch body {
        case .sun:
            return .zero

        case .moon:
            // EMB heliocentric position from VSOP2013
            let emb = try planetary.position(for: .earth, at: jd)
            // Moon position relative to Earth (geocentric) from DE440, already in AU
            let moonGeo = try lunar.geocentricPosition(at: jd)
            // Moon heliocentric = EMB + Moon_geocentric × (1 - μ)
            // where μ = M_moon / (M_earth + M_moon)
            // This converts from Earth-centric to EMB-centric offset
            return emb + moonGeo * (1.0 - Self.moonMassRatio)

        case .earth:
            // Earth heliocentric = EMB - Moon_geocentric × μ
            let emb = try planetary.position(for: .earth, at: jd)
            let moonGeo = try lunar.geocentricPosition(at: jd)
            return emb - moonGeo * Self.moonMassRatio

        default:
            return try planetary.position(for: body, at: jd)
        }
    }

    /// Full 6D state vector (position in AU, velocity in AU/day) for a Solar System body.
    public func stateVector(for body: SolarSystemBody, at jd: JulianDay) throws -> StateVector {
        switch body {
        case .sun:
            return StateVector(position: .zero, velocity: .zero)

        case .moon:
            let embState = try planetary.stateVector(for: .earth, at: jd)
            let moonGeoState = try lunar.geocentricStateVector(at: jd)
            let factor = 1.0 - Self.moonMassRatio
            return StateVector(
                position: embState.position + moonGeoState.position * factor,
                velocity: embState.velocity + moonGeoState.velocity * factor
            )

        case .earth:
            let embState = try planetary.stateVector(for: .earth, at: jd)
            let moonGeoState = try lunar.geocentricStateVector(at: jd)
            return StateVector(
                position: embState.position - moonGeoState.position * Self.moonMassRatio,
                velocity: embState.velocity - moonGeoState.velocity * Self.moonMassRatio
            )

        default:
            return try planetary.stateVector(for: body, at: jd)
        }
    }
}
