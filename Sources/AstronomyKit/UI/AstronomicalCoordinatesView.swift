//
//  AstronomicalCoordinatesView.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import SwiftUI

/// Formatted, copyable sexagesimal coordinates display for equatorial coordinates.
public struct AstronomicalCoordinatesView: View {
    public let coordinates: EquatorialCoordinates
    public let label: String
    @State private var showingCopiedNotification: Bool = false

    public init(coordinates: EquatorialCoordinates, label: String = "Equatorial Coordinates (J2000)") {
        self.coordinates = coordinates
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                if showingCopiedNotification {
                    Text("Copied!")
                        .font(.caption2.bold())
                        .foregroundStyle(.tint)
                        .transition(.opacity)
                }
            }

            HStack(spacing: 20) {
                coordinateItem(
                    title: "α (Right Ascension)",
                    value: coordinates.rightAscension.formatted(.rightAscension)
                )

                coordinateItem(
                    title: "δ (Declination)",
                    value: coordinates.declination.formatted(.sexagesimal)
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): Right ascension \(coordinates.rightAscension.formatted(.rightAscension)), Declination \(coordinates.declination.formatted(.sexagesimal))")
    }

    private func coordinateItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }
}
#endif
