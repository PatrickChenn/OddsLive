//
//  OddsCellViewModel.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Combine
import Foundation

enum OddsTrend {
    case up
    case down
    case unchanged
}

struct OddsDisplayState {
    let value: Double
    let trend: OddsTrend
}

@MainActor
final class OddsCellViewModel {
    let matchID: Int
    let teamA: String
    let teamB: String
    let startTime: Date
    let teamAOdds = CurrentValueSubject<OddsDisplayState, Never>(OddsDisplayState(value: 0, trend: .unchanged))
    let teamBOdds = CurrentValueSubject<OddsDisplayState, Never>(OddsDisplayState(value: 0, trend: .unchanged))

    init(matchData: MatchOdds) {
        matchID = matchData.matchID
        teamA = matchData.teamA
        teamB = matchData.teamB
        startTime = matchData.startTime
        teamAOdds.value = OddsDisplayState(value: matchData.teamAOdds, trend: .unchanged)
        teamBOdds.value = OddsDisplayState(value: matchData.teamBOdds, trend: .unchanged)
    }

    func apply(odds: Odds) {
        teamAOdds.send(
            OddsDisplayState(
                value: odds.teamAOdds,
                trend: makeTrend(current: odds.teamAOdds, previous: teamAOdds.value.value)
            )
        )
        teamBOdds.send(
            OddsDisplayState(
                value: odds.teamBOdds,
                trend: makeTrend(current: odds.teamBOdds, previous: teamBOdds.value.value)
            )
        )
    }

    private func makeTrend(current: Double, previous: Double) -> OddsTrend {
        if current > previous {
            return .up
        }

        if current < previous {
            return .down
        }

        return .unchanged
    }
}
