//
//  MatchWebSocketService.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Foundation

enum MatchWebSocketConnectionState: Equatable {
    case connected
    case disconnected
    case reconnecting
}

protocol MatchWebSocketProviding {
    func start(
        onOddsUpdate: @escaping @MainActor ([Odds]) -> Void,
        onConnectionStateChange: @escaping @MainActor (MatchWebSocketConnectionState) -> Void,
        onReconnectCountdownChange: @escaping @MainActor (Int?) -> Void
    )
    func stop()
}

@MainActor
final class MatchWebSocketService: MatchWebSocketProviding {
    private let matchIDs: [Int]
    private let disconnectInterval: Int
    private let reconnectDelay: TimeInterval

    private var onOddsUpdate: (@MainActor ([Odds]) -> Void)?
    private var onConnectionStateChange: (@MainActor (MatchWebSocketConnectionState) -> Void)?
    private var onReconnectCountdownChange: (@MainActor (Int?) -> Void)?

    private var updateLoopTask: Task<Void, Never>?
    private var reconnectCountdownTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var disconnectTickCount = 0
    private var connectionState: MatchWebSocketConnectionState = .disconnected
    private var hasStarted = false

    init(
        matchIDs: [Int]? = nil,
        disconnectInterval: Int = 10,
        reconnectDelay: TimeInterval = 2
    ) {
        self.matchIDs = matchIDs ?? MatchAPIService()
            .fetchLocalMatches()
            .map(\.matchID)
        self.disconnectInterval = disconnectInterval
        self.reconnectDelay = reconnectDelay
    }

    func start(
        onOddsUpdate: @escaping @MainActor ([Odds]) -> Void,
        onConnectionStateChange: @escaping @MainActor (MatchWebSocketConnectionState) -> Void,
        onReconnectCountdownChange: @escaping @MainActor (Int?) -> Void
    ) {
        self.onOddsUpdate = onOddsUpdate
        self.onConnectionStateChange = onConnectionStateChange
        self.onReconnectCountdownChange = onReconnectCountdownChange

        guard !hasStarted else { return }
        hasStarted = true
        beginConnectedSession()
    }

    func stop() {
        hasStarted = false
        updateLoopTask?.cancel()
        reconnectCountdownTask?.cancel()
        reconnectTask?.cancel()
        updateLoopTask = nil
        reconnectCountdownTask = nil
        reconnectTask = nil
        disconnectTickCount = 0
        onReconnectCountdownChange?(nil)
        onConnectionStateChange?(.disconnected)
    }

    private func beginConnectedSession() {
        updateLoopTask?.cancel()
        reconnectTask?.cancel()
        reconnectCountdownTask?.cancel()
        updateLoopTask = nil
        reconnectTask = nil
        reconnectCountdownTask = nil
        disconnectTickCount = 0
        connectionState = .connected
        onReconnectCountdownChange?(nil)
        onConnectionStateChange?(.connected)
        updateLoopTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                guard self.connectionState == .connected else { return }

                self.disconnectTickCount += 1

                if self.disconnectTickCount >= self.disconnectInterval {
                    self.disconnect()
                    return
                }

                self.onOddsUpdate?(Self.makeMockWebSocketUpdates(matchIDs: self.matchIDs))
            }
        }
    }

    private func disconnect() {
        updateLoopTask?.cancel()
        updateLoopTask = nil
        connectionState = .disconnected
        onConnectionStateChange?(.disconnected)
        startReconnectCountdown()
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            guard let self else { return }

            let reconnectingDelay = min(0.5, reconnectDelay)
            try? await Task.sleep(for: .seconds(reconnectingDelay))
            guard !Task.isCancelled else { return }
            self.connectionState = .reconnecting
            self.onConnectionStateChange?(.reconnecting)

            let remainingDelay = max(reconnectDelay - reconnectingDelay, 0)
            if remainingDelay > 0 {
                try? await Task.sleep(for: .seconds(remainingDelay))
            }
            guard !Task.isCancelled else { return }
            self.beginConnectedSession()
        }
    }

    private func startReconnectCountdown() {
        reconnectCountdownTask?.cancel()
        let initialSeconds = max(Int(ceil(reconnectDelay)), 1)
        onReconnectCountdownChange?(initialSeconds)

        guard initialSeconds > 1 else {
            return
        }

        reconnectCountdownTask = Task { [weak self] in
            guard let self else { return }
            var remainingSeconds = initialSeconds

            while remainingSeconds > 1 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remainingSeconds -= 1
                self.onReconnectCountdownChange?(remainingSeconds)
            }
        }
    }
}

private extension MatchWebSocketService {
    static func makeMockWebSocketUpdates(matchIDs: [Int]) -> [Odds] {
        let updateCount = min(Int.random(in: 5...10), matchIDs.count)
        return matchIDs
            .shuffled()
            .prefix(updateCount)
            .map { matchID in
                Odds(
                    matchID: matchID,
                    teamAOdds: rounded(Double.random(in: 1.1...3.5)),
                    teamBOdds: rounded(Double.random(in: 1.1...3.5))
                )
            }
    }

    static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
