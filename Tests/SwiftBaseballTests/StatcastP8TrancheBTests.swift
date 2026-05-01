import Foundation
@testable import SwiftBaseball
import Testing

// MARK: - Active Spin

@Suite("Active Spin Tests")
struct ActiveSpinTests {
    private func loadEntries() throws -> [ActiveSpinEntry] {
        let data = try Fixtures.load("active_spin_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return ActiveSpinParser.parse(csv, season: 2024)
    }

    @Test("Wide CSV flattens to one entry per (pitcher × non-empty pitch type)")
    func flattens() throws {
        let entries = try loadEntries()
        // 15 pitchers × 2–4 non-empty pitch types each → between 30 and 60 entries.
        #expect(entries.count > 25)
        #expect(entries.count < 75)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Whitlock entry decodes with expected pitch types and values")
    func whitlockEntry() throws {
        let entries = try loadEntries()
        let whitlock = entries.filter { $0.pitcherId == 676_477 }
        let types = Set(whitlock.map(\.pitchType))
        #expect(types == ["SI", "FC", "CH", "SL", "ST"])
        let si = try #require(whitlock.first { $0.pitchType == "SI" })
        #expect(abs(si.activeSpinPercent - 98.7) < 0.0001)
        #expect(si.pitcherName == "Whitlock, Garrett")
        #expect(si.pitchHand == "R")
    }

    @Test("Active spin values land on 0–100 scale (not normalized)")
    func zeroToHundred() throws {
        let entries = try loadEntries()
        // At least one value above 1 is sufficient to confirm we did not normalize.
        #expect(entries.contains { $0.activeSpinPercent > 1 })
        #expect(entries.allSatisfy { $0.activeSpinPercent >= 0 && $0.activeSpinPercent <= 100 })
    }

    @Test("Empty cells produce no entries for that pitch type")
    func emptyCellsSkipped() throws {
        let entries = try loadEntries()
        // Whitlock does not throw a four-seam fastball in the fixture.
        let whitlock = entries.filter { $0.pitcherId == 676_477 }
        let whitlockTypes = Set(whitlock.map(\.pitchType))
        #expect(!whitlockTypes.contains("FF"))
    }

    @Test("Endpoint URL targets /leaderboard/active-spin with year")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/active-spin", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("active-spin"))
        #expect(built.absoluteString.contains("year=2024"))
    }
}

// MARK: - Running Splits

@Suite("Running Splits Tests")
struct RunningSplitsTests {
    private func loadEntries() throws -> [RunningSplitsEntry] {
        let data = try Fixtures.load("running_splits_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return RunningSplitsParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 rows from fixture")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry — Abrams — splits decode with expected values")
    func topEntry() throws {
        let entries = try loadEntries()
        let top = try #require(entries.first)
        #expect(top.playerId == 682_928)
        #expect(top.playerName == "Abrams, CJ")
        #expect(top.team == "WSH")
        #expect(top.position == "SS")
        #expect(top.age == 23)
        #expect(top.batSide == "L")
        #expect(top.secondsTo0ft == 0.0)
        #expect(abs((top.secondsTo5ft ?? 0) - 0.54) < 0.0001)
        #expect(abs((top.secondsTo90ft ?? 0) - 3.87) < 0.0001)
    }

    @Test("Switch hitters appear once per bat side")
    func switchHitter() throws {
        let entries = try loadEntries()
        let albies = entries.filter { $0.playerId == 645_277 }
        #expect(albies.count == 2)
        let sides = Set(albies.map(\.batSide))
        #expect(sides == ["L", "R"])
    }

    @Test("Cumulative split times are monotonic")
    func monotonic() throws {
        let entries = try loadEntries()
        let abrams = try #require(entries.first { $0.playerId == 682_928 })
        // Every 5-foot mark, in order; assert each is >= the previous.
        let splits: [Double?] = [
            abrams.secondsTo0ft, abrams.secondsTo5ft, abrams.secondsTo10ft,
            abrams.secondsTo15ft, abrams.secondsTo20ft, abrams.secondsTo25ft,
            abrams.secondsTo30ft, abrams.secondsTo35ft, abrams.secondsTo40ft,
            abrams.secondsTo45ft, abrams.secondsTo50ft, abrams.secondsTo55ft,
            abrams.secondsTo60ft, abrams.secondsTo65ft, abrams.secondsTo70ft,
            abrams.secondsTo75ft, abrams.secondsTo80ft, abrams.secondsTo85ft,
            abrams.secondsTo90ft
        ]
        var previous = 0.0
        for split in splits {
            let value = try #require(split)
            #expect(value >= previous)
            previous = value
        }
    }

    @Test("Endpoint URL targets /leaderboard/running_splits with raw splits_type")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/running_splits", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "1"),
            URLQueryItem(name: "splits_type", value: "raw"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("running_splits"))
        #expect(built.absoluteString.contains("splits_type=raw"))
    }
}

// MARK: - Bat Tracking

@Suite("Bat Tracking Tests")
struct BatTrackingTests {
    private func loadEntries() throws -> [BatTrackingEntry] {
        let data = try Fixtures.load("bat_tracking_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return BatTrackingParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 rows from fixture")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry — Caminero — bat-speed leader fields decode")
    func topEntry() throws {
        let entries = try loadEntries()
        let top = try #require(entries.first)
        #expect(top.playerId == 691_406)
        #expect(top.playerName == "Caminero, Junior")
        #expect(top.competitiveSwings == 189)
        #expect(top.contact == 147)
        #expect(abs(top.avgBatSpeed - 79.605564603) < 0.0001)
        #expect(abs(top.hardSwingRate - 0.8518518518518519) < 0.0001)
        #expect(abs(top.avgSwingLength - 8.693839365) < 0.0001)
        #expect(top.swords == 2)
        #expect(top.whiffs == 42)
        #expect(top.battedBallEvents == 85)
    }

    @Test("Rate fields land on 0–1 scale (not 0–100)")
    func zeroToOne() throws {
        let entries = try loadEntries()
        // All rates must be ≤ 1 on this board (Savant publishes fractions, not percents).
        for entry in entries {
            #expect(entry.competitiveSwingRate <= 1)
            #expect(entry.hardSwingRate <= 1)
            #expect(entry.squaredUpPerContact <= 1)
            #expect(entry.squaredUpPerSwing <= 1)
            #expect(entry.blastPerContact <= 1)
            #expect(entry.blastPerSwing <= 1)
            #expect(entry.whiffPerSwing <= 1)
            #expect(entry.battedBallEventPerSwing <= 1)
        }
    }

    @Test("Run value field parses with sign")
    func runValueSign() throws {
        let entries = try loadEntries()
        // Negative run values exist in the fixture (e.g. Smith, Cam).
        #expect(entries.contains { $0.batterRunValue < 0 })
        #expect(entries.contains { $0.batterRunValue > 0 })
    }

    @Test("Endpoint URL targets /leaderboard/bat-tracking with attackZone")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/bat-tracking", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "attackZone", value: "all"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("bat-tracking"))
        #expect(built.absoluteString.contains("attackZone=all"))
    }
}

// MARK: - Outfield Catch Probability

@Suite("Outfield Catch Probability Tests")
struct OutfieldCatchProbabilityTests {
    private func loadEntries() throws -> [OutfieldCatchProbabilityEntry] {
        let data = try Fixtures.load("outfield_catch_prob_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return OutfieldCatchProbabilityParser.parse(csv, season: 2024)
    }

    @Test("Decodes all 15 fixture rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry (Jacob Young) parses headline buckets")
    func topEntry() throws {
        let entries = try loadEntries()
        let young = try #require(entries.first)
        #expect(young.playerId == 696_285)
        #expect(young.playerName == "Young, Jacob")
        #expect(young.outsAboveAverage == 20)
        #expect(young.fiveStarOpportunities == 26)
        #expect(young.fiveStarOuts == 10)
        #expect(abs((young.fiveStarCatchPercent ?? 0) - 38.5) < 0.0001)
        #expect(abs((young.oneStarCatchPercent ?? 0) - 100.0) < 0.0001)
    }

    @Test("Empty bucket percent decodes to nil (Michael A. Taylor 4-star)")
    func emptyBucketIsNil() throws {
        let entries = try loadEntries()
        let taylor = try #require(entries.first { $0.playerId == 572_191 })
        #expect(taylor.fourStarOpportunities == 0)
        #expect(taylor.fourStarOuts == 0)
        #expect(taylor.fourStarCatchPercent == nil)
    }

    @Test("Catch percentages land on 0–100 scale (not normalized)")
    func zeroToHundred() throws {
        let entries = try loadEntries()
        let allPercents = entries.flatMap {
            [$0.fiveStarCatchPercent, $0.fourStarCatchPercent, $0.threeStarCatchPercent,
             $0.twoStarCatchPercent, $0.oneStarCatchPercent].compactMap(\.self)
        }
        #expect(allPercents.contains { $0 > 1 })
        #expect(allPercents.allSatisfy { $0 >= 0 && $0 <= 100 })
    }

    @Test("Endpoint URL targets /leaderboard/catch_probability with year")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/catch_probability", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("catch_probability"))
        #expect(built.absoluteString.contains("year=2024"))
    }
}

// MARK: - Outfielder Jumps

@Suite("Outfielder Jumps Tests")
struct OutfielderJumpsTests {
    private func loadEntries() throws -> [OutfielderJumpEntry] {
        let data = try Fixtures.load("outfielder_jumps_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return OutfielderJumpsParser.parse(csv, season: 2024)
    }

    @Test("Decodes all 15 fixture rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry (Wilyer Abreu) parses jump components")
    func topEntry() throws {
        let entries = try loadEntries()
        let abreu = try #require(entries.first)
        #expect(abreu.playerId == 677_800)
        #expect(abreu.playerName == "Abreu, Wilyer")
        #expect(abreu.outsAboveAverage == 6)
        #expect(abs(abreu.outsPerPlay - 61.1) < 0.0001)
        #expect(abreu.relLeagueBurstDistance == 0)
        #expect(abs(abreu.relLeagueReactionDistance - 0.6) < 0.0001)
        #expect(abs(abreu.fBootupDistance - 34.9) < 0.0001)
        #expect(abreu.opportunities == 54)
        #expect(abreu.outs == 33)
    }

    @Test("Negative rel-league distances preserved (Andujar reaction is positive but routing negative)")
    func signedDistances() throws {
        let entries = try loadEntries()
        let andujar = try #require(entries.first { $0.playerId == 609_280 })
        #expect(andujar.relLeagueBurstDistance < 0)
        #expect(andujar.relLeagueReactionDistance > 0)
        #expect(andujar.relLeagueRoutingDistance < 0)
        #expect(andujar.outsAboveAverage == -6)
    }

    @Test("Bootup absolute distance is in realistic ft range (30–40)")
    func bootupRange() throws {
        let entries = try loadEntries()
        #expect(entries.allSatisfy { $0.fBootupDistance >= 30 && $0.fBootupDistance <= 40 })
    }

    @Test("Endpoint URL targets /leaderboard/outfield_jump with year")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/outfield_jump", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("outfield_jump"))
        #expect(built.absoluteString.contains("year=2024"))
    }
}
