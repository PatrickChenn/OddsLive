//
//  OddsPageViewModel.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Combine
import Foundation

@MainActor
class OddsPageViewModel {
    private let api: MatchAPIProviding
    private let webSocketService: MatchWebSocketProviding
    private let cacheStore: MatchOddsCacheStore

    private(set) var matchList: [OddsCellViewModel] = []
    private var isLoading = false {
        didSet {
            guard oldValue != isLoading else { return }
            onLoadingStateChanged?(isLoading)
        }
    }

    var onInitialDataLoaded: (() -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onConnectionStateChanged: ((MatchWebSocketConnectionState) -> Void)?
    var onReconnectCountdownChanged: ((Int?) -> Void)?
    var onError: ((String) -> Void)?

    init(
        api: MatchAPIProviding? = nil,
        webSocketService: MatchWebSocketProviding? = nil,
        cacheStore: MatchOddsCacheStore = .shared
    ) {
        self.api = api ?? MatchAPIService()
        self.webSocketService = webSocketService ?? MatchWebSocketService()
        self.cacheStore = cacheStore
    }

    func start() async {
        let cachedMatchOdds = await cacheStore.snapshot()
        if cachedMatchOdds.isEmpty {
            await fetchMatchOddsData()
        } else {
            apply(matchOddsList: cachedMatchOdds)
        }

        onInitialDataLoaded?()
        startOddsUpdates()
    }

    func stop() {
        webSocketService.stop()
    }

    private func fetchMatchOddsData() async {
        setLoading(true)
        do {
            async let matches = api.fetchMatches()
            async let oddsList = api.fetchOdds()

            matchList = try await MatchOdds
                .merge(matches: matches, oddsList: oddsList)
                .sorted { $0.startTime < $1.startTime }
                .map(OddsCellViewModel.init)
            await cacheStore.save(makeMatchOddsListSnapshot())
            setLoading(false)
        } catch {
            setLoading(false)
            onError?("fetchMatchOddsData error: \(error)")
        }
    }

    private func startOddsUpdates() {
        webSocketService.start(
            onOddsUpdate: { [weak self] updatedOddsList in
                self?.applyOddsUpdates(updatedOddsList)
            },
            onConnectionStateChange: { [weak self] state in
                self?.onConnectionStateChanged?(state)
            },
            onReconnectCountdownChange: { [weak self] seconds in
                self?.onReconnectCountdownChanged?(seconds)
            }
        )
    }

    private func applyOddsUpdates(_ updatedOddsList: [Odds]) {
        let matchDataByMatchID = Dictionary(uniqueKeysWithValues: matchList.map { ($0.matchID, $0) })

        updatedOddsList.forEach { odds in
            guard let matchData = matchDataByMatchID[odds.matchID] else {
                return
            }
            matchData.apply(odds: odds)
        }

        Task {
            await cacheStore.apply(oddsUpdates: updatedOddsList)
        }
    }

    private func apply(matchOddsList: [MatchOdds]) {
        matchList = matchOddsList
            .sorted { $0.startTime < $1.startTime }
            .map(OddsCellViewModel.init)
    }

    private func makeMatchOddsListSnapshot() -> [MatchOdds] {
        matchList.map { item in
            MatchOdds(
                matchID: item.matchID,
                teamA: item.teamA,
                teamB: item.teamB,
                teamAOdds: item.teamAOdds.value.value,
                teamBOdds: item.teamBOdds.value.value,
                startTime: item.startTime
            )
        }
    }

    private func setLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
