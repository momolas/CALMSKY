//
//  ObservationSession.swift
//  AstronomyKit
//
//  Created for AstronomyKit.
//  MIT Licence. See LICENCE file.
//

import Foundation
import SwiftData

/// Represents an observing session during a specific night or daytime observation run.
@Model
public final class ObservationSession {
    #Index<ObservationSession>([\.date])

    public var date: Date = Date.now
    public var observerName: String = ""
    public var seeingScale: Int = 3 // 1 (excellent) to 5 (terrible) Antoniadi scale
    public var transparency: Int = 3 // 1 (poor) to 5 (exceptional)
    public var telescopeDescription: String = ""
    public var weatherNotes: String = ""

    public var location: ObserverLocation?

    @Relationship(deleteRule: .cascade, inverse: \ObservationLog.session)
    public var logs: [ObservationLog] = []

    public init(
        date: Date = .now,
        observerName: String = "",
        seeingScale: Int = 3,
        transparency: Int = 3,
        telescopeDescription: String = "",
        weatherNotes: String = "",
        location: ObserverLocation? = nil
    ) {
        self.date = date
        self.observerName = observerName
        self.seeingScale = seeingScale
        self.transparency = transparency
        self.telescopeDescription = telescopeDescription
        self.weatherNotes = weatherNotes
        self.location = location
    }

    /// Corresponding Julian Day for the session date.
    public var julianDay: JulianDay {
        JulianDay(date)
    }
}
