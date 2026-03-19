//
//  OddsLiveTests.swift
//  OddsLiveTests
//
//  Created by Patrick on 2026/3/17.
//

import Testing
@testable import OddsLive

struct OddsLiveTests {

    @Test
    @MainActor
    func matchAPIServiceReturnsMatchesAndOdds() async throws {
        let service = MatchAPIService()
        let matches = try await service.fetchMatches()
        let odds = try await service.fetchOdds()

        #expect(matches.count == 100)
        #expect(odds.count == 100)
        #expect(matches.first?.teamA == "皇家馬德里")
        #expect(matches.first?.teamB == "皇家貝提斯")
        #expect(odds.first?.matchID == matches.first?.matchID)
        #expect(odds.first?.teamAOdds == 1.6)
        #expect(odds.first?.teamBOdds == 1.72)
    }

    @Test
    @MainActor
    func matchWebSocketServiceEmitsOddsUpdatesForKnownMatchIDs() async throws {
        let apiService = MatchAPIService()
        let matches = try await apiService.fetchMatches()
        let validMatchIDs = Set(matches.map(\.matchID))
        let socketService = MatchWebSocketService(matchIDs: Array(validMatchIDs))
        let updatesTask = Task { @MainActor in
            await withCheckedContinuation { continuation in
                var didResume = false
                socketService.start(
                    onOddsUpdate: { updates in
                        guard !didResume else { return }
                        didResume = true
                        continuation.resume(returning: updates)
                    },
                    onConnectionStateChange: { _ in },
                    onReconnectCountdownChange: { _ in }
                )
            }
        }

        let updates = await updatesTask.value
        socketService.stop()

        #expect((5...10).contains(updates.count))
        #expect(updates.allSatisfy { validMatchIDs.contains($0.matchID) })
    }

    @Test
    @MainActor
    func matchWebSocketServiceReconnectsAfterDisconnect() async throws {
        let socketService = MatchWebSocketService(
            matchIDs: [1001, 1002, 1003],
            disconnectInterval: 2,
            reconnectDelay: 0.5
        )
        let reconnectingStateTask = Task { @MainActor in
            await withCheckedContinuation { continuation in
                var didResume = false
                socketService.start(
                    onOddsUpdate: { _ in },
                    onConnectionStateChange: { state in
                        guard state == .reconnecting, !didResume else { return }
                        didResume = true
                        continuation.resume(returning: state)
                    },
                    onReconnectCountdownChange: { _ in }
                )
            }
        }

        let reconnectingState = await reconnectingStateTask.value
        socketService.stop()
        #expect(reconnectingState == .reconnecting)
    }

}
