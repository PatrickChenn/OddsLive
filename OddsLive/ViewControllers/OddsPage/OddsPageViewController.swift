//
//  OddsPageViewController.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/17.
//

import UIKit

class OddsPageViewController: UIViewController {
    private let statusContainerView = UIView()
    private let statusStackView = UIStackView()
    private let statusLabel = UILabel()
    private let countdownLabel = UILabel()
    private let statusNoteLabel = UILabel()
    private let loadingView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    private let loadingStackView = UIStackView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let viewModel = OddsPageViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stop()
    }

    private func configureUI() {
        statusContainerView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.backgroundColor = .secondarySystemBackground
        statusContainerView.layer.cornerRadius = 10
        statusContainerView.layer.cornerCurve = .continuous

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textAlignment = .center

        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        countdownLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        countdownLabel.textAlignment = .right
        countdownLabel.textColor = .secondaryLabel
        countdownLabel.isHidden = true

        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.axis = .horizontal
        statusStackView.alignment = .center
        statusStackView.distribution = .fill
        statusStackView.spacing = 8

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.88)
        loadingView.isHidden = true

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = false

        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.font = .systemFont(ofSize: 15, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = .secondaryLabel
        loadingLabel.text = "Loading latest odds..."

        loadingStackView.translatesAutoresizingMaskIntoConstraints = false
        loadingStackView.axis = .vertical
        loadingStackView.alignment = .center
        loadingStackView.spacing = 12

        statusNoteLabel.translatesAutoresizingMaskIntoConstraints = false
        statusNoteLabel.font = .systemFont(ofSize: 12)
        statusNoteLabel.textColor = .secondaryLabel
        statusNoteLabel.numberOfLines = 0
        statusNoteLabel.textAlignment = .left
        statusNoteLabel.text = "This demo simulates a WebSocket disconnect and reconnect every 10 seconds."

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(OddsCell.self, forCellReuseIdentifier: OddsCell.reuseIdentifier)
        view.addSubview(statusContainerView)
        statusContainerView.addSubview(statusStackView)
        statusContainerView.addSubview(statusNoteLabel)
        statusStackView.addArrangedSubview(statusLabel)
        statusStackView.addArrangedSubview(countdownLabel)
        view.addSubview(tableView)
        view.addSubview(loadingView)
        loadingView.addSubview(loadingStackView)
        loadingStackView.addArrangedSubview(loadingIndicator)
        loadingStackView.addArrangedSubview(loadingLabel)

        NSLayoutConstraint.activate([
            statusContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            statusContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            statusContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            statusStackView.topAnchor.constraint(equalTo: statusContainerView.topAnchor, constant: 8),
            statusStackView.leadingAnchor.constraint(equalTo: statusContainerView.leadingAnchor, constant: 12),
            statusStackView.trailingAnchor.constraint(equalTo: statusContainerView.trailingAnchor, constant: -12),

            statusNoteLabel.topAnchor.constraint(equalTo: statusStackView.bottomAnchor, constant: 4),
            statusNoteLabel.leadingAnchor.constraint(equalTo: statusStackView.leadingAnchor),
            statusNoteLabel.trailingAnchor.constraint(equalTo: statusStackView.trailingAnchor),
            statusNoteLabel.bottomAnchor.constraint(equalTo: statusContainerView.bottomAnchor, constant: -8),

            tableView.topAnchor.constraint(equalTo: statusContainerView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingStackView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingStackView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])

        updateConnectionState(.disconnected)
        updateReconnectCountdown(nil)
        updateLoadingState(false)
    }

    private func bindViewModel() {
        viewModel.onInitialDataLoaded = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }

        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                self?.updateLoadingState(isLoading)
            }
        }

        viewModel.onConnectionStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.updateConnectionState(state)
            }
        }

        viewModel.onReconnectCountdownChanged = { [weak self] seconds in
            DispatchQueue.main.async {
                self?.updateReconnectCountdown(seconds)
            }
        }

        viewModel.onError = { message in
            print(message)
        }

        Task { [weak self] in
            guard let self else { return }
            await self.viewModel.start()
        }
    }

    private func updateConnectionState(_ state: MatchWebSocketConnectionState) {
        switch state {
        case .connected:
            statusLabel.text = "WebSocket Connected"
            statusLabel.textColor = .systemGreen
        case .disconnected:
            statusLabel.text = "WebSocket Disconnected"
            statusLabel.textColor = .systemRed
        case .reconnecting:
            statusLabel.text = "WebSocket Reconnecting..."
            statusLabel.textColor = .systemOrange
        }
    }

    private func updateReconnectCountdown(_ seconds: Int?) {
        guard let seconds else {
            countdownLabel.isHidden = true
            countdownLabel.text = nil
            return
        }

        countdownLabel.isHidden = false
        countdownLabel.text = "Reconnect in \(seconds)s"
    }

    private func updateLoadingState(_ isLoading: Bool) {
        loadingView.isHidden = !isLoading

        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
}

extension OddsPageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.matchList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: OddsCell.reuseIdentifier,
            for: indexPath
        ) as? OddsCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.matchList[indexPath.row])
        return cell
    }
}

extension OddsPageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
