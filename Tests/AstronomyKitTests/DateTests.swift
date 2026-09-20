//
//  DateTests.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 2017-09-19.
//  Copyright © 2017 onekiloparsec. All rights reserved.
//

import Testing
@testable import AstronomyKit

@Suite("DateTests")
struct DateTests {

    @Test("Date Setting Hour")
    func testDateSettingHour() {
        var components = DateComponents()
        components.year = 1916
        components.month = 9
        components.day = 17
        components.hour = 2
        components.minute = 3
        components.second = 4
        components.nanosecond = 500000000
        let date = Calendar.gregorianGMT.date(from: components)!
        let newDate = Calendar.gregorianGMT.date(bySettingHour: 3.45678, of: date)
        
        #expect(Calendar.gregorianGMT.component(.hour , from: newDate) == 3)
        #expect(Calendar.gregorianGMT.component(.minute , from: newDate) == 27)
        #expect(Calendar.gregorianGMT.component(.second , from: newDate) == 23)
        #expect(Calendar.gregorianGMT.component(.nanosecond , from: newDate) == 999911785)
    }


}
