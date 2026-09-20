//
//  LunarPhaseView.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

#if canImport(SwiftUI)
import SwiftUI

/// A vectorial, HIG-compliant SwiftUI view displaying the Moon's phase with illumination shading.
public struct LunarPhaseView: View {
    public let phase: LunarPhase
    public let illumination: Double
    public let size: CGFloat

    public init(phase: LunarPhase, illumination: Double, size: CGFloat = 80) {
        self.phase = phase
        self.illumination = max(0.0, min(1.0, illumination))
        self.size = size
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Dark lunar disk (Earthshine)
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: size, height: size)

                // Illuminated phase representation
                phaseGraphic
                    .frame(width: size, height: size)
                    .clipShape(Circle())

                // Limb highlight
                Circle()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    .frame(width: size, height: size)
            }

            VStack(spacing: 2) {
                Text(phase.name)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                Text(illumination, format: .percent.precision(.fractionLength(0)))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.name), \(illumination.formatted(.percent.precision(.fractionLength(0)))) illuminated")
    }

    @ViewBuilder
    private var phaseGraphic: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let midX = rect.midX
            let midY = rect.midY
            let r = min(rect.width, rect.height) / 2.0

            let isWaxing = phase.isWaxing
            let phaseColor = Color(white: 0.95)

            // Fill illuminated hemisphere base
            var baseHemisphere = Path()
            if isWaxing {
                // Right side illuminated
                baseHemisphere.addArc(center: CGPoint(x: midX, y: midY), radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            } else {
                // Left side illuminated
                baseHemisphere.addArc(center: CGPoint(x: midX, y: midY), radius: r, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            }
            baseHemisphere.closeSubpath()
            context.fill(baseHemisphere, with: .color(phaseColor))

            // Draw terminator elliptical boundary
            // illumination fraction k in [0, 1]. Width factor = 2*k - 1 in [-1, 1]
            let k = illumination
            let factor = CGFloat(2.0 * k - 1.0)

            var terminator = Path()
            terminator.move(to: CGPoint(x: midX, y: midY - r))

            // Elliptical curve from top to bottom
            let cpX = midX + (factor * r * (isWaxing ? 1.0 : -1.0))
            terminator.addCurve(
                to: CGPoint(x: midX, y: midY + r),
                control1: CGPoint(x: cpX, y: midY - (r * 0.55)),
                control2: CGPoint(x: cpX, y: midY + (r * 0.55))
            )

            // Close along base hemisphere side
            if k < 0.5 {
                // Crescent: subtract over illuminated side
                context.fill(terminator, with: .color(Color(white: 0.15)))
            } else {
                // Gibbous: add onto dark side
                context.fill(terminator, with: .color(phaseColor))
            }
        }
    }
}
#endif
