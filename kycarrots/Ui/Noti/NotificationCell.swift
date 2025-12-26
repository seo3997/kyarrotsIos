//
//  NotificationCell.swift
//  kycarrots
//
//  Created by soo on 12/26/25.
//


import UIKit

final class NotificationCell: UITableViewCell {
    static let reuseId = "NotificationCell"

    private let unreadDot = UIView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let metaLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        unreadDot.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.layer.cornerRadius = 4
        unreadDot.backgroundColor = .systemBlue

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 2

        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2

        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.font = .systemFont(ofSize: 12)
        metaLabel.textColor = .tertiaryLabel

        contentView.addSubview(unreadDot)
        contentView.addSubview(titleLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(metaLabel)

        NSLayoutConstraint.activate([
            unreadDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            unreadDot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            unreadDot.widthAnchor.constraint(equalToConstant: 8),
            unreadDot.heightAnchor.constraint(equalToConstant: 8),

            titleLabel.leadingAnchor.constraint(equalTo: unreadDot.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            metaLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func bind(_ item: PushNotification) {
        titleLabel.text = item.title
        bodyLabel.text = item.body ?? ""
        metaLabel.text = "\(item.type) · \(Self.format(item.createdAt))"

        unreadDot.alpha = item.isRead ? 0.25 : 1.0
    }

    private static func format(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: d)
    }
}
