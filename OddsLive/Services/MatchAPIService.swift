//
//  MatchAPIService.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Foundation

protocol MatchAPIProviding {
    func fetchMatches() async throws -> [Match]
    func fetchOdds() async throws -> [Odds]
}

struct MatchAPIService: MatchAPIProviding {
    func fetchMatches() async throws -> [Match] {
        try await Task.sleep(nanoseconds: Self.randomDelayNanoseconds())
        return fetchLocalMatches()
    }

    func fetchOdds() async throws -> [Odds] {
        try await Task.sleep(nanoseconds: Self.randomDelayNanoseconds())
        return Self.load([Odds].self, fileName: "odds")
    }

    func fetchLocalMatches() -> [Match] {
        Self.load([Match].self, fileName: "matches")
            .enumerated()
            .map { index, match in
                Match(
                    matchID: match.matchID,
                    teamA: match.teamA,
                    teamB: match.teamB,
                    startTime: Self.makeUpcomingStartTime(index: index)
                )
            }
    }
}

private extension MatchAPIService {
    static func randomDelayNanoseconds() -> UInt64 {
        UInt64.random(in: 100_000_000...3_000_000_000)
    }

    static func makeUpcomingStartTime(index: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let nextHour = calendar.nextDate(
            after: now,
            matching: DateComponents(minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? now

        return calendar.date(byAdding: .hour, value: index * 2, to: nextHour) ?? nextHour
    }

    static func load<T: Decodable>(_ type: T.Type, fileName: String) -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let url = try bundledResourceURL(fileName: fileName, fileExtension: "json")
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Failed to load \(fileName).json: \(error)")
        }
    }

    static func bundledResourceURL(fileName: String, fileExtension: String) throws -> URL {
        if let bundledURL = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension,
            subdirectory: "MockData"
        ) {
            return bundledURL
        }

        if let bundledURL = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension
        ) {
            return bundledURL
        }

        let resourceName = "\(fileName).\(fileExtension)"
        if let bundledURL = Bundle.main.urls(
            forResourcesWithExtension: fileExtension,
            subdirectory: nil
        )?.first(where: { $0.lastPathComponent == resourceName }) {
            return bundledURL
        }

        throw NSError(
            domain: "MatchAPIService",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Missing bundled resource \(resourceName)"]
        )
    }
}
