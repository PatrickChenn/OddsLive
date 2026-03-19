//
//  MatchOddsModel.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Foundation

struct Match: Decodable, Sendable, Equatable {
    let matchID: Int
    let teamA: String
    let teamB: String
    let startTime: Date
}

struct Odds: Decodable, Sendable, Equatable {
    let matchID: Int
    let teamAOdds: Double
    let teamBOdds: Double
}

struct MatchOdds: Sendable, Equatable {
    let matchID: Int
    let teamA: String
    let teamB: String
    let teamAOdds: Double
    let teamBOdds: Double
    let startTime: Date

    static func merge(matches: [Match], oddsList: [Odds]) -> [MatchOdds] {
        let oddsByMatchID = Dictionary(uniqueKeysWithValues: oddsList.map { ($0.matchID, $0) })

        return matches.compactMap { match in
            guard let odds = oddsByMatchID[match.matchID] else {
                return nil
            }

            return MatchOdds(
                matchID: match.matchID,
                teamA: match.teamA,
                teamB: match.teamB,
                teamAOdds: odds.teamAOdds,
                teamBOdds: odds.teamBOdds,
                startTime: match.startTime
            )
        }
    }
}
