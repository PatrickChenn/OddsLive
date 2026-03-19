//
//  OddsCell.swift
//  OddsLive
//
//  Created by Patrick on 2026/3/18.
//

import Combine
import UIKit

final class OddsCell: UITableViewCell {
    static let reuseIdentifier = "OddsCell"

    private let cardView = UIView()
    private let teamALabel = UILabel()
    private let teamBLabel = UILabel()
    private let startTimeLabel = UILabel()
    private let teamAOddsLabel = UILabel()
    private let teamBOddsLabel = UILabel()
    private let contentStackView = UIStackView()
    private let teamsStackView = UIStackView()
    private let oddsStackView = UIStackView()
    private var cancellables = Set<AnyCancellable>()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        teamALabel.text = nil
        teamBLabel.text = nil
        teamAOddsLabel.textColor = .label
        teamBOddsLabel.textColor = .label
    }

    func configure(with item: OddsCellViewModel) {
        cancellables.removeAll()
        teamALabel.text = item.teamA
        teamBLabel.text = item.teamB
        startTimeLabel.text = dateFormatter.string(from: item.startTime)
        updateOddsLabel(teamAOddsLabel, state: item.teamAOdds.value)
        updateOddsLabel(teamBOddsLabel, state: item.teamBOdds.value)
        
        item.teamAOdds
            .sink { [weak self] state in
                self?.updateOddsLabel(
                    self?.teamAOddsLabel,
                    state: state
                )
            }
            .store(in: &cancellables)

        item.teamBOdds
            .sink { [weak self] state in
                self?.updateOddsLabel(
                    self?.teamBOddsLabel,
                    state: state
                )
            }
            .store(in: &cancellables)
    }

    private func updateOddsLabel(_ label: UILabel?, state: OddsDisplayState) {
        guard let label else { return }
        let formattedOdds = String(format: "%.2f", state.value)

        switch state.trend {
        case .up:
            label.text = "↑\(formattedOdds)"
            label.textColor = .systemRed
        case .down:
            label.text = "↓\(formattedOdds)"
            label.textColor = .systemGreen
        case .unchanged:
            label.text = formattedOdds
            label.textColor = .label
        }
    }

    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.cornerCurve = .continuous

        teamALabel.font = .systemFont(ofSize: 16, weight: .semibold)
        teamALabel.textColor = .label
        teamALabel.textAlignment = .left
        teamALabel.numberOfLines = 1
        teamALabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        teamBLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        teamBLabel.textColor = .label
        teamBLabel.textAlignment = .left
        teamBLabel.numberOfLines = 1
        teamBLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        startTimeLabel.font = .systemFont(ofSize: 13)
        startTimeLabel.textColor = .secondaryLabel
        startTimeLabel.textAlignment = .left
        startTimeLabel.numberOfLines = 1
        startTimeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        startTimeLabel.setContentHuggingPriority(.required, for: .vertical)

        teamAOddsLabel.textAlignment = .right
        teamAOddsLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        teamAOddsLabel.textColor = .label
        teamAOddsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        teamBOddsLabel.textAlignment = .right
        teamBOddsLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        teamBOddsLabel.textColor = .label
        teamBOddsLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .horizontal
        contentStackView.alignment = .top
        contentStackView.spacing = 12

        teamsStackView.translatesAutoresizingMaskIntoConstraints = false
        teamsStackView.axis = .vertical
        teamsStackView.alignment = .fill
        teamsStackView.spacing = 10
        teamsStackView.addArrangedSubview(teamALabel)
        teamsStackView.addArrangedSubview(teamBLabel)

        oddsStackView.translatesAutoresizingMaskIntoConstraints = false
        oddsStackView.axis = .vertical
        oddsStackView.alignment = .fill
        oddsStackView.spacing = 10
        oddsStackView.addArrangedSubview(teamAOddsLabel)
        oddsStackView.addArrangedSubview(teamBOddsLabel)

        contentStackView.addArrangedSubview(teamsStackView)
        contentStackView.addArrangedSubview(oddsStackView)

        contentView.addSubview(cardView)
        cardView.addSubview(startTimeLabel)
        cardView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            startTimeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            startTimeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            startTimeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            contentStackView.topAnchor.constraint(equalTo: startTimeLabel.bottomAnchor, constant: 10),
            contentStackView.leadingAnchor.constraint(equalTo: startTimeLabel.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: startTimeLabel.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),

            oddsStackView.widthAnchor.constraint(equalToConstant: 64)
        ])
    }
}
