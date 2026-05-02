import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Postseason Tests")
struct PostseasonTests {
    @Test("Postseason schedule decodes flat list of games")
    func scheduleDecodes() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("postseason_schedule_2024.json")
        mock.stub(path: "schedule/postseason", data: data)

        let games = try await QueryBuilder<[ScheduleEntry]>
            .postseasonSchedule(season: 2024, client: mock)
            .fetch()

        #expect(games.count == 43)
        let opener = try #require(games.first)
        #expect(opener.gameType == .wildCard)
        #expect(opener.season == "2024")
        #expect(opener.seriesDescription == "AL Wild Card Series")
        let finale = try #require(games.last)
        #expect(finale.gameType == .worldSeries)
    }

    @Test("Postseason schedule query uses dedicated path with sportId + season")
    func scheduleEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("postseason_schedule_2024.json")
        mock.stub(path: "schedule/postseason", data: data)

        _ = try await QueryBuilder<[ScheduleEntry]>
            .postseasonSchedule(season: 2024, client: mock)
            .fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "schedule/postseason")
        let params = Dictionary(uniqueKeysWithValues: endpoint.queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        #expect(params["sportId"] == "1")
        #expect(params["season"] == "2024")
    }

    @Test("Postseason series decodes 11 series across 4 rounds")
    func seriesDecodes() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("postseason_series_2024.json")
        mock.stub(path: "schedule/postseason/series", data: data)

        let series = try await QueryBuilder<[PostseasonSeries]>
            .postseasonSeries(season: 2024, client: mock)
            .fetch()

        #expect(series.count == 11)
        let worldSeries = try #require(series.first { $0.gameType == .worldSeries })
        #expect(worldSeries.id == "W_1")
        #expect(worldSeries.totalGames == 5)
        #expect(worldSeries.games.count == 5)
        let opener = try #require(worldSeries.games.first)
        #expect(opener.teams.away.team.name.contains("Yankees"))
        #expect(opener.teams.home.team.name.contains("Dodgers"))
    }

    @Test("Series rounds cover Wild Card, Division, LCS, World Series")
    func seriesRoundCoverage() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("postseason_series_2024.json")
        mock.stub(path: "schedule/postseason/series", data: data)

        let series = try await QueryBuilder<[PostseasonSeries]>
            .postseasonSeries(season: 2024, client: mock)
            .fetch()

        let rounds = Set(series.map(\.gameType))
        #expect(rounds == [.wildCard, .divisionSeries, .leagueChampionship, .worldSeries])
    }

    @Test("Series query uses postseason/series path")
    func seriesEndpointPath() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("postseason_series_2024.json")
        mock.stub(path: "schedule/postseason/series", data: data)

        _ = try await QueryBuilder<[PostseasonSeries]>
            .postseasonSeries(season: 2024, client: mock)
            .fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "schedule/postseason/series")
    }
}
