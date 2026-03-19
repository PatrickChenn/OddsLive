//
//  MatchOddsCacheStore.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Foundation

actor MatchOddsCacheStore {
    static let shared = MatchOddsCacheStore()

    private var cachedMatchOdds: [MatchOdds] = []

    func snapshot() -> [MatchOdds] {
        cachedMatchOdds
    }

    func save(_ matchOddsList: [MatchOdds]) {
        cachedMatchOdds = matchOddsList
    }

    func apply(oddsUpdates: [Odds]) {
        guard !cachedMatchOdds.isEmpty else { return }

        let oddsByMatchID = Dictionary(uniqueKeysWithValues: oddsUpdates.map { ($0.matchID, $0) })
        cachedMatchOdds = cachedMatchOdds.map { item in
            guard let updatedOdds = oddsByMatchID[item.matchID] else {
                return item
            }

            return MatchOdds(
                matchID: item.matchID,
                teamA: item.teamA,
                teamB: item.teamB,
                teamAOdds: updatedOdds.teamAOdds,
                teamBOdds: updatedOdds.teamBOdds,
                startTime: item.startTime
            )
        }
    }
}
