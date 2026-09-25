//
//  AstronomicalCoordinatesView.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

                Button("Copy", systemImage: "doc.on.doc") {
                    copyToPasteboard()
                }
                .labelStyle(.iconOnly)
                .font(.caption)
                .buttonStyle(.borderless)
                .accessibilityLabel("Copy coordinates to clipboard")
            }

            HStack(spacing: 20) {
                CoordinateItemView(
                    title: "α (Right Ascension)",
                    value: coordinates.rightAscension.formatted(.rightAscension)
                )

                CoordinateItemView(
                    title: "δ (Declination)",
                    value: coordinates.declination.formatted(.sexagesimal)
                )
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        .sensoryFeedback(.success, trigger: showingCopiedNotification)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): Right ascension \(coordinates.rightAscension.formatted(.rightAscension)), Declination \(coordinates.declination.formatted(.sexagesimal))")
    }

    private func copyToPasteboard() {
        let text = "\(coordinates.rightAscension.formatted(.rightAscension)) \(coordinates.declination.formatted(.sexagesimal))"
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif

        withAnimation(.easeInOut(duration: 0.2)) {
            showingCopiedNotification = true
        }

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.2)) {
                showingCopiedNotification = false
            }
        }
    }
}

// MARK: - Subview

private struct CoordinateItemView: View {
    let title: String
    let value: String

    var body: some View {
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
