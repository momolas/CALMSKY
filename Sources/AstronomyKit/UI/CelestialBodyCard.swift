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
                headerSection
                Divider()
                coordinatesSection
                if snapshot.apparentMagnitude != nil || snapshot.illuminatedFraction != nil {
                    Divider()
                    metricsSection
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(colorTint.opacity(0.3), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorTint.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(snapshot.body.symbol)
                    .font(.title2)
                    .foregroundStyle(colorTint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.body.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(bodyTypeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let mag = snapshot.apparentMagnitude {
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

    private var coordinatesSection: some View {
        HStack(spacing: 16) {
            if let eq = snapshot.equatorialCoordinates {
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
                    Text("\(snapshot.radiusVector.value, format: .number.precision(.fractionLength(3))) AU")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var metricsSection: some View {
        HStack(spacing: 16) {
            if let frac = snapshot.illuminatedFraction {
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
                Text("\(snapshot.radiusVector.value, format: .number.precision(.fractionLength(2))) AU")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
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
#endif
