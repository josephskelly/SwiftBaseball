import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Meta Catalogs Tests")
struct MetaCatalogsTests {
    // MARK: - Stat catalogs

    @Test("statTypes decodes 61 entries with displayName")
    func statTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "statTypes", data: try Fixtures.load("meta_statTypes.json"))
        let entries = try await QueryBuilder<[MetaStatType]>
            .metaCatalog(path: "statTypes", client: mock)
            .fetch()
        #expect(entries.count == 61)
        #expect(entries.contains { $0.displayName == "season" })
    }

    @Test("statGroups decodes hitting/pitching/fielding")
    func statGroups() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "statGroups", data: try Fixtures.load("meta_statGroups.json"))
        let entries = try await QueryBuilder<[MetaStatGroup]>
            .metaCatalog(path: "statGroups", client: mock)
            .fetch()
        #expect(entries.count == 8)
        let names = Set(entries.map(\.displayName))
        #expect(names.isSuperset(of: ["hitting", "pitching", "fielding"]))
    }

    @Test("statFields decodes name-only entries")
    func statFields() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "statFields", data: try Fixtures.load("meta_statFields.json"))
        let entries = try await QueryBuilder<[MetaStatField]>
            .metaCatalog(path: "statFields", client: mock)
            .fetch()
        #expect(entries.count == 8)
        #expect(entries.contains { $0.name == "standard" })
    }

    @Test("leagueLeaderTypes decodes displayName-only entries")
    func leagueLeaderTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "leagueLeaderTypes", data: try Fixtures.load("meta_leagueLeaderTypes.json"))
        let entries = try await QueryBuilder<[MetaLeagueLeaderType]>
            .metaCatalog(path: "leagueLeaderTypes", client: mock)
            .fetch()
        #expect(entries.count == 70)
        #expect(entries.contains { $0.displayName == "homeRuns" })
    }

    @Test("baseballStats decodes 25 stats with statGroups")
    func baseballStats() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "baseballStats", data: try Fixtures.load("meta_baseballStats.json"))
        let entries = try await QueryBuilder<[MetaBaseballStat]>
            .metaCatalog(path: "baseballStats", client: mock)
            .fetch()
        #expect(entries.count == 25)
        let airOuts = try #require(entries.first { $0.name == "airOuts" })
        #expect(airOuts.lookupParam == "ao")
        #expect(airOuts.isCounting == true)
        #expect(airOuts.statGroups?.contains { $0.displayName == "pitching" } == true)
    }

    // MARK: - Game / roster / standings

    @Test("gameTypes decodes 12 entries with id+description")
    func gameTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "gameTypes", data: try Fixtures.load("meta_gameTypes.json"))
        let entries = try await QueryBuilder<[MetaGameType]>
            .metaCatalog(path: "gameTypes", client: mock)
            .fetch()
        #expect(entries.count == 12)
        let regular = try #require(entries.first { $0.id == "R" })
        #expect(regular.description == "Regular Season")
    }

    @Test("rosterTypes decodes lookupName + parameter")
    func rosterTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "rosterTypes", data: try Fixtures.load("meta_rosterTypes.json"))
        let entries = try await QueryBuilder<[MetaRosterType]>
            .metaCatalog(path: "rosterTypes", client: mock)
            .fetch()
        #expect(entries.count == 9)
        let fortyMan = try #require(entries.first { $0.lookupName == "40man" })
        #expect(fortyMan.parameter == "40Man")
    }

    @Test("standingsTypes decodes regularSeason + variants")
    func standingsTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "standingsTypes", data: try Fixtures.load("meta_standingsTypes.json"))
        let entries = try await QueryBuilder<[MetaStandingsType]>
            .metaCatalog(path: "standingsTypes", client: mock)
            .fetch()
        #expect(entries.count == 13)
        #expect(entries.contains { $0.name == "regularSeason" })
        #expect(entries.contains { $0.name == "wildCard" })
    }

    // MARK: - Pitch / event / situation

    @Test("pitchTypes decodes 24 codes with description")
    func pitchTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "pitchTypes", data: try Fixtures.load("meta_pitchTypes.json"))
        let entries = try await QueryBuilder<[MetaPitchType]>
            .metaCatalog(path: "pitchTypes", client: mock)
            .fetch()
        #expect(entries.count == 24)
        #expect(entries.contains { $0.code == "FA" && $0.description == "Fastball" })
    }

    @Test("pitchCodes decodes swing/strike attributes")
    func pitchCodes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "pitchCodes", data: try Fixtures.load("meta_pitchCodes.json"))
        let entries = try await QueryBuilder<[MetaPitchCode]>
            .metaCatalog(path: "pitchCodes", client: mock)
            .fetch()
        #expect(entries.count == 39)
        let calledStrike = try #require(entries.first { $0.code == "C" })
        #expect(calledStrike.description == "Strike - Called")
        #expect(calledStrike.strikeStatus == true)
        #expect(calledStrike.swingStatus == false)
    }

    @Test("eventTypes decodes plateAppearance + hit flags")
    func eventTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "eventTypes", data: try Fixtures.load("meta_eventTypes.json"))
        let entries = try await QueryBuilder<[MetaEventType]>
            .metaCatalog(path: "eventTypes", client: mock)
            .fetch()
        #expect(entries.count == 25)
        let pickoff = try #require(entries.first { $0.code == "pickoff_1b" })
        #expect(pickoff.baseRunningEvent == true)
        #expect(pickoff.plateAppearance == false)
        #expect(pickoff.hit == false)
    }

    @Test("situationCodes decodes batting/pitching flags + sortOrder")
    func situationCodes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "situationCodes", data: try Fixtures.load("meta_situationCodes.json"))
        let entries = try await QueryBuilder<[MetaSituationCode]>
            .metaCatalog(path: "situationCodes", client: mock)
            .fetch()
        #expect(entries.count == 25)
        let home = try #require(entries.first { $0.code == "h" })
        #expect(home.description == "Home Games")
        #expect(home.team == true)
        #expect(home.batting == true)
    }

    // MARK: - Misc

    @Test("positions decodes 37 entries with formalName")
    func positions() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "positions", data: try Fixtures.load("meta_positions.json"))
        let entries = try await QueryBuilder<[MetaPosition]>
            .metaCatalog(path: "positions", client: mock)
            .fetch()
        #expect(entries.count == 37)
        let pitcher = try #require(entries.first { $0.code == "1" })
        #expect(pitcher.formalName == "Pitcher")
        #expect(pitcher.abbrev == "P")
    }

    @Test("reviewReasons decodes 27 entries")
    func reviewReasons() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "reviewReasons", data: try Fixtures.load("meta_reviewReasons.json"))
        let entries = try await QueryBuilder<[MetaReviewReason]>
            .metaCatalog(path: "reviewReasons", client: mock)
            .fetch()
        #expect(entries.count == 27)
        let tag = try #require(entries.first { $0.code == "A" })
        #expect(tag.description == "Tag play")
    }

    @Test("hitTrajectories decodes 7 entries")
    func hitTrajectories() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "hitTrajectories", data: try Fixtures.load("meta_hitTrajectories.json"))
        let entries = try await QueryBuilder<[MetaHitTrajectory]>
            .metaCatalog(path: "hitTrajectories", client: mock)
            .fetch()
        #expect(entries.count == 7)
        #expect(entries.contains { $0.code == "bunt_grounder" })
    }

    @Test("logicalEvents decodes code-only entries")
    func logicalEvents() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "logicalEvents", data: try Fixtures.load("meta_logicalEvents.json"))
        let entries = try await QueryBuilder<[MetaLogicalEvent]>
            .metaCatalog(path: "logicalEvents", client: mock)
            .fetch()
        #expect(entries.count == 73)
        #expect(entries.contains { $0.code == "sceneStateUpdate" })
    }

    @Test("jobTypes decodes 25 jobs with sortOrder")
    func jobTypes() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "jobTypes", data: try Fixtures.load("meta_jobTypes.json"))
        let entries = try await QueryBuilder<[MetaJobType]>
            .metaCatalog(path: "jobTypes", client: mock)
            .fetch()
        #expect(entries.count == 25)
        let umpire = try #require(entries.first { $0.code == "UMPR" })
        #expect(umpire.job == "Umpire")
        #expect(umpire.sortOrder == 1)
    }

    @Test("languages decodes locale + languageCode")
    func languages() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "languages", data: try Fixtures.load("meta_languages.json"))
        let entries = try await QueryBuilder<[MetaLanguage]>
            .metaCatalog(path: "languages", client: mock)
            .fetch()
        #expect(entries.count == 16)
        let english = try #require(entries.first { $0.languageCode == "en" })
        #expect(english.locale == "en_US")
        #expect(english.name == "English")
    }

    // MARK: - Namespace integration

    @Test("SwiftBaseball.meta.statTypes() routes to statTypes path")
    func metaNamespaceRoutesPath() async throws {
        let mock = MockAPIClient()
        mock.stub(path: "statTypes", data: try Fixtures.load("meta_statTypes.json"))

        let builder = QueryBuilder<[MetaStatType]>
            .metaCatalog(path: "statTypes", client: mock)
        _ = try await builder.fetch()

        #expect(mock.lastEndpoint?.path == "statTypes")
    }
}
