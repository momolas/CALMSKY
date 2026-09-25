//
//  CelestialBodyCard.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import SwiftUI

/// An elevated, HIG-compliant SwiftUI card displaying live astronomical ephemeris for a celestial body.
public struct CelestialBodyCard: View {
    public let snapshot: EphemerisSnapshot
    public let onSelect: (() -> Void)?

    public init(snapshot: EphemerisSnapshot, onSelect: (() -> Void)? = nil) {
        self.snapshot = snapshot
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 12) {
                CardHeaderSection(
                    name: snapshot.body.name,
                    symbol: snapshot.body.symbol,
                    bodyType: bodyTypeDescription,
                    magnitude: snapshot.apparentMagnitude,
                    tint: colorTint
                )
                Divider()
                CardCoordinatesSection(
                    equatorialCoordinates: snapshot.equatorialCoordinates,
                    radiusVectorAU: snapshot.radiusVector.value
                )
                if snapshot.apparentMagnitude != nil || snapshot.illuminatedFraction != nil {
                    Divider()
                    CardMetricsSection(
                        illuminatedFraction: snapshot.illuminatedFraction,
                        radiusVectorAU: snapshot.radiusVector.value
                    )
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle.rect(cornerRadius: 16)
                    .strokeBorder(colorTint.opacity(0.3), lineWidth: 1)
            )
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var colorTint: Color {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return Color(nsColor: snapshot.body.averageColor)
        #elseif canImport(UIKit)
        return Color(uiColor: snapshot.body.averageColor)
        #else
        let c = snapshot.body.averageColor
        return Color(red: c.red, green: c.green, blue: c.blue)
        #endif
    }

    private var bodyTypeDescription: String {
        switch snapshot.body {
        case .sun: return "Star"
        case .moon: return "Natural Satellite"
        case .pluto: return "Dwarf Planet"
        default: return "Major Planet"
        }
    }

    private var accessibilityDescription: String {
        var desc = "\(snapshot.body.name), \(bodyTypeDescription)"
        if let mag = snapshot.apparentMagnitude {
            desc += ", apparent magnitude \(mag.formatted(.number.precision(.fractionLength(1))))"
        }
        if let eq = snapshot.equatorialCoordinates {
            desc += ", right ascension \(eq.rightAscension.formatted(.rightAscension)), declination \(eq.declination.formatted(.sexagesimal))"
        }
        return desc
    }
}

// MARK: - Dedicated Subviews

private struct CardHeaderSection: View {
    let name: String
    let symbol: String
    let bodyType: String
    let magnitude: Double?
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(symbol)
                    .font(.title2)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(bodyType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let mag = magnitude {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(mag, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("mag")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                )
            }
        }
    }
}

private struct CardCoordinatesSection: View {
    let equatorialCoordinates: EquatorialCoordinates?
    let radiusVectorAU: Double

    var body: some View {
        HStack(spacing: 16) {
            if let eq = equatorialCoordinates {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Right Ascension")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(eq.rightAscension.formatted(.rightAscension))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Declination")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(eq.declination.formatted(.sexagesimal))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance to Sun")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(radiusVectorAU, format: .number.precision(.fractionLength(3))) AU")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

private struct CardMetricsSection: View {
    let illuminatedFraction: Double?
    let radiusVectorAU: Double

    var body: some View {
        HStack(spacing: 16) {
            if let frac = illuminatedFraction {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(frac, format: .percent.precision(.fractionLength(0)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "ruler")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(radiusVectorAU, format: .number.precision(.fractionLength(2))) AU")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
#endif
