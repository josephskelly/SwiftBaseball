import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Venue Tests")
struct VenueTests {
    // MARK: - Single venue

    @Test("Single venue parsed correctly")
    func parseVenue() async throws {
        let data = try Fixtures.load("venue_3313.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues/3313", data: data)

        let venue = try await QueryBuilder<Venue>.venue(id: 3313, client: mock).fetch()

        #expect(venue.id == 3313)
        #expect(venue.name == "Yankee Stadium")
        #expect(venue.active == true)
    }

    @Test("Venue location fields parsed correctly")
    func venueLocation() async throws {
        let data = try Fixtures.load("venue_3313.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues/3313", data: data)

        let venue = try await QueryBuilder<Venue>.venue(id: 3313, client: mock).fetch()

        #expect(venue.city == "Bronx")
        #expect(venue.state == "New York")
        #expect(venue.stateAbbrev == "NY")
        #expect(venue.country == "USA")
    }

    @Test("Venue coordinates parsed correctly")
    func venueCoordinates() async throws {
        let data = try Fixtures.load("venue_3313.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues/3313", data: data)

        let venue = try await QueryBuilder<Venue>.venue(id: 3313, client: mock).fetch()

        let coords = try #require(venue.coordinates)
        #expect(abs(coords.latitude - 40.82919482) < 0.00001)
        #expect(abs(coords.longitude - -73.9264977) < 0.00001)
    }

    @Test("Venue field dimensions parsed correctly")
    func venueFieldDimensions() async throws {
        let data = try Fixtures.load("venue_3313.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues/3313", data: data)

        let venue = try await QueryBuilder<Venue>.venue(id: 3313, client: mock).fetch()

        let dims = try #require(venue.dimensions)
        #expect(dims.leftLine == 318)
        #expect(dims.leftCenter == 399)
        #expect(dims.center == 408)
        #expect(dims.rightCenter == 385)
        #expect(dims.rightLine == 314)
    }

    @Test("Venue surface and roof type parsed correctly")
    func venueSurfaceAndRoof() async throws {
        let data = try Fixtures.load("venue_3313.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues/3313", data: data)

        let venue = try await QueryBuilder<Venue>.venue(id: 3313, client: mock).fetch()

        #expect(venue.surface == "Grass")
        #expect(venue.roofType == "Open")
        #expect(venue.capacity == 47309)
    }

    @Test("Venue missing fieldInfo returns nil dimensions and nil capacity")
    func venueNoDimensions() async throws {
        let json = """
        {
          "venues": [
            {
              "id": 999,
              "name": "Test Park",
              "active": true
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let mock = MockAPIClient()
        mock.stub(path: "venues/999", data: data)

        let venue = try await QueryBuilder<Venue>.venue(id: 999, client: mock).fetch()

        #expect(venue.dimensions == nil)
        #expect(venue.coordinates == nil)
        #expect(venue.capacity == nil)
    }

    @Test("Venue not found throws notFound error")
    func venueNotFound() async throws {
        let json = """
        {"venues": []}
        """
        let data = Data(json.utf8)
        let mock = MockAPIClient()
        mock.stub(path: "venues/9999", data: data)

        do {
            _ = try await QueryBuilder<Venue>.venue(id: 9999, client: mock).fetch()
            Issue.record("Expected notFound error to be thrown")
        } catch SwiftBaseballError.notFound {
            // expected
        }
    }

    // MARK: - Venues list

    @Test("Venues list returns all entries")
    func venuesList() async throws {
        let data = try Fixtures.load("venues_sample.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues", data: data)

        let venues = try await QueryBuilder<[Venue]>.venues(client: mock).fetch()

        #expect(venues.count == 3)
    }

    @Test("Venues list: optional intermediate distances parsed")
    func venuesOptionalDistances() async throws {
        let data = try Fixtures.load("venues_sample.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues", data: data)

        let venues = try await QueryBuilder<[Venue]>.venues(client: mock).fetch()

        // Angel Stadium has `left` and `right` intermediate values
        let angel = try #require(venues.first { $0.id == 1 })
        #expect(angel.dimensions?.left == 347)
        #expect(angel.dimensions?.right == 348)
        // Yankee Stadium does not have intermediate values
        let yankee = try #require(venues.first { $0.id == 3313 })
        #expect(yankee.dimensions?.left == nil)
    }

    @Test("Venues list: retractable roof venue parsed correctly")
    func venuesRetractableRoof() async throws {
        let data = try Fixtures.load("venues_sample.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues", data: data)

        let venues = try await QueryBuilder<[Venue]>.venues(client: mock).fetch()

        let houston = try #require(venues.first { $0.id == 2392 })
        #expect(houston.roofType == "Retractable")
        #expect(houston.dimensions?.center == 409)
    }

    @Test("Venues list: coordinates populated for all entries")
    func venuesAllHaveCoordinates() async throws {
        let data = try Fixtures.load("venues_sample.json")
        let mock = MockAPIClient()
        mock.stub(path: "venues", data: data)

        let venues = try await QueryBuilder<[Venue]>.venues(client: mock).fetch()

        #expect(venues.allSatisfy { $0.coordinates != nil })
    }

    // MARK: - Entry points

    @Test("SwiftBaseball.venue(id:) returns Venue query")
    func namespacedVenue() {
        let query = SwiftBaseball.venue(id: 3313)
        _ = query
    }

    @Test("SwiftBaseball.venues() returns Venue list query")
    func namespacedVenues() {
        let query = SwiftBaseball.venues()
        _ = query.season(2024)
    }
}
