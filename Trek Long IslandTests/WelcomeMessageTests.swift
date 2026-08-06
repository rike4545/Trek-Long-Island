// Copyright Bryan Carroll. All rights reserved.
//
//  WelcomeMessageTests.swift
//  Trek Long IslandTests
//
//  Covers the splash greeting that Settings › Identity drives, plus the
//  trapping-conversion guards that back the numbers shown around the app.
//

import Foundation
import Testing
@testable import Trek_Long_Island

private func date(hour: Int) -> Date {
    var components = DateComponents()
    components.year = 2027
    components.month = 6
    components.day = 12
    components.hour = hour
    components.minute = 0
    return Calendar.current.date(from: components) ?? .now
}

struct WelcomeMessageTests {

    // MARK: - Greeting styles

    @Test func timeOfDayGreetingTracksTheClock() {
        func greeting(atHour hour: Int) -> String {
            TLIProfilePreferences.welcomeGreeting(
                style: .timeOfDay,
                customMessage: "",
                rank: .captain,
                displayName: "Bryan",
                pronouns: "",
                showPronouns: false,
                date: date(hour: hour)
            )
        }

        #expect(greeting(atHour: 8) == "Good morning, Captain Bryan")
        #expect(greeting(atHour: 14) == "Good afternoon, Captain Bryan")
        #expect(greeting(atHour: 21) == "Good evening, Captain Bryan")
        #expect(greeting(atHour: 3) == "Good evening, Captain Bryan")
    }

    @Test func fixedStylesUseTheCommandName() {
        #expect(
            TLIProfilePreferences.welcomeGreeting(
                style: .welcomeAboard,
                customMessage: "",
                rank: .commander,
                displayName: "Bryan",
                pronouns: "",
                showPronouns: false
            ) == "Welcome aboard, Commander Bryan"
        )

        #expect(
            TLIProfilePreferences.welcomeGreeting(
                style: .hailing,
                customMessage: "",
                rank: .none,
                displayName: "Bryan",
                pronouns: "",
                showPronouns: false
            ) == "Bridge to Bryan"
        )
    }

    @Test func customMessageSubstitutesTheNameToken() {
        #expect(
            TLIProfilePreferences.welcomeGreeting(
                style: .custom,
                customMessage: "Live long and prosper, {name}",
                rank: .captain,
                displayName: "Bryan",
                pronouns: "",
                showPronouns: false
            ) == "Live long and prosper, Captain Bryan"
        )
    }

    @Test func customMessageWithoutTokenIsUsedVerbatim() {
        #expect(
            TLIProfilePreferences.welcomeGreeting(
                style: .custom,
                customMessage: "Engage.",
                rank: .captain,
                displayName: "Bryan",
                pronouns: "",
                showPronouns: false
            ) == "Engage."
        )
    }

    @Test func emptyCustomMessageFallsBackToTimeOfDay() {
        #expect(
            TLIProfilePreferences.welcomeGreeting(
                style: .custom,
                customMessage: "   ",
                rank: .captain,
                displayName: "Bryan",
                pronouns: "",
                showPronouns: false,
                date: date(hour: 8)
            ) == "Good morning, Captain Bryan"
        )
    }

    // MARK: - Pronouns

    @Test func pronounsAppendOnlyWhenEnabledAndPresent() {
        func greeting(pronouns: String, show: Bool) -> String {
            TLIProfilePreferences.welcomeGreeting(
                style: .welcomeAboard,
                customMessage: "",
                rank: .captain,
                displayName: "Bryan",
                pronouns: pronouns,
                showPronouns: show
            )
        }

        #expect(greeting(pronouns: "they / them", show: true) == "Welcome aboard, Captain Bryan (they / them)")
        #expect(greeting(pronouns: "they / them", show: false) == "Welcome aboard, Captain Bryan")
        #expect(greeting(pronouns: "", show: true) == "Welcome aboard, Captain Bryan")
    }

    @Test func pronounsDisplayResolvesPresetsAndCustomText() {
        #expect(TLIProfilePreferences.pronounsDisplay(selection: .unspecified, custom: "ignored") == "")
        #expect(TLIProfilePreferences.pronounsDisplay(selection: .theyThem, custom: "") == "they / them")
        #expect(TLIProfilePreferences.pronounsDisplay(selection: .askMe, custom: "") == "ask me")
        #expect(TLIProfilePreferences.pronounsDisplay(selection: .custom, custom: "  ze / zir  ") == "ze / zir")
        #expect(TLIProfilePreferences.pronounsDisplay(selection: .custom, custom: "   ") == "")
    }

    // MARK: - Input clamping

    @Test func customMessageIsCollapsedAndLengthCapped() {
        let messy = "Welcome\n\n   aboard,\t{name}"
        #expect(TLIProfilePreferences.sanitizedSingleLine(messy, limit: 90) == "Welcome aboard, {name}")

        let long = String(repeating: "a", count: 500)
        let clamped = TLIProfilePreferences.sanitizedSingleLine(long, limit: TLIProfilePreferences.customWelcomeMessageLimit)
        #expect(clamped.count == TLIProfilePreferences.customWelcomeMessageLimit)
    }

    @Test func rawStorageValuesFallBackToDefaults() {
        #expect(TLIProfilePreferences.welcomeStyle(from: "not-a-style") == .timeOfDay)
        #expect(TLIProfilePreferences.pronouns(from: "not-a-pronoun") == .unspecified)
    }
}

struct SafeMathTests {

    @Test func intConversionSurvivesNonFiniteValues() {
        #expect(TLISafeMath.int(Double.nan) == 0)
        #expect(TLISafeMath.int(Double.infinity) == 0)
        #expect(TLISafeMath.int(-Double.infinity) == 0)
        #expect(TLISafeMath.int(Double.greatestFiniteMagnitude) == 0)
        #expect(TLISafeMath.int(42.9) == 42)
        #expect(TLISafeMath.int(Double.nan, fallback: 7) == 7)
    }

    @Test func roundedSurvivesNonFiniteValues() {
        #expect(TLISafeMath.rounded(Double.nan) == 0)
        #expect(TLISafeMath.rounded(2.6) == 3)
        #expect(TLISafeMath.rounded(Double.infinity, fallback: -1) == -1)
    }

    @Test func percentClampsToZeroThroughOneHundred() {
        // 0/0 is exactly the shape that used to crash the ops analytics tiles.
        let zeroOverZero = Double(0) / Double(0)
        #expect(TLISafeMath.percent(zeroOverZero) == 0)
        #expect(TLISafeMath.percent(0.5) == 50)
        #expect(TLISafeMath.percent(1.0) == 100)
        #expect(TLISafeMath.percent(4.2) == 100)
        #expect(TLISafeMath.percent(-3.0) == 0)
        #expect(TLISafeMath.percent(Float.nan) == 0)
    }

    @Test func minutesClampsAbsurdIntervals() {
        #expect(TLISafeMath.minutes(600) == 10)
        #expect(TLISafeMath.minutes(.nan) == 0)
        #expect(TLISafeMath.minutes(.infinity) > 0)
        // A distant-future event date must not trap the conversion.
        #expect(TLISafeMath.minutes(Date.distantFuture.timeIntervalSinceNow) > 0)
        #expect(TLISafeMath.minutes(Date.distantPast.timeIntervalSinceNow) < 0)
    }
}
