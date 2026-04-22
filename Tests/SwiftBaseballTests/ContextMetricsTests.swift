import Foundation
@testable import SwiftBaseball
import Testing

@Suite("ContextMetrics Tests")
struct ContextMetricsTests {
    private func loadMetrics() throws -> GameContextMetrics {
        let data = try Fixtures.load("context_metrics_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBContextMetricsResponse.self, from: data)
        return MLBResponseConverters.contextMetrics(from: response)
    }

    @Test("gamePk is lifted out of the game wrapper")
    func gamePkDecodes() throws {
        let metrics = try loadMetrics()
        #expect(metrics.gamePk == 745_612)
    }

    @Test("Final-state win probabilities are 0/100")
    func finalStateWinProbabilities() throws {
        let metrics = try loadMetrics()
        #expect(metrics.homeWinProbability == 0.0)
        #expect(metrics.awayWinProbability == 100.0)
    }

    @Test("Win probabilities sum to 100")
    func winProbabilitiesSum() throws {
        let metrics = try loadMetrics()
        let total = metrics.homeWinProbability + metrics.awayWinProbability
        #expect(abs(total - 100.0) < 0.001)
    }

    @Test("Missing probabilities default to zero")
    func missingProbabilitiesDefaultToZero() throws {
        let json = #"{"game":{"gamePk":1234}}"#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBContextMetricsResponse.self, from: data)
        let metrics = MLBResponseConverters.contextMetrics(from: response)

        #expect(metrics.gamePk == 1234)
        #expect(metrics.homeWinProbability == 0.0)
        #expect(metrics.awayWinProbability == 0.0)
    }

    @Test("Endpoint URL targets /game/{pk}/contextMetrics")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "game/745612/contextMetrics")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/game/745612/contextMetrics")
    }
}
