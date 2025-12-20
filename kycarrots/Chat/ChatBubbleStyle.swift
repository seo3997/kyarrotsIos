//
//  ChatBubbleStyle.swift
//  kycarrots
//
//  Created by soo on 12/20/25.
//


import UIKit

enum ChatBubbleStyle {
    static func applyLeft(bubbleView: UIView, messageLabel: UILabel, timeLabel: UILabel) {
        bubbleView.backgroundColor = UIColor.systemGray6
        bubbleView.layer.cornerRadius = 14
        bubbleView.layer.masksToBounds = true

        messageLabel.textColor = .label
        messageLabel.numberOfLines = 0

        timeLabel.textColor = UIColor.systemGray
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = .left
    }

    static func applyRight(bubbleView: UIView, messageLabel: UILabel, timeLabel: UILabel) {
        bubbleView.backgroundColor = UIColor.systemGreen
        bubbleView.layer.cornerRadius = 14
        bubbleView.layer.masksToBounds = true

        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0

        timeLabel.textColor = UIColor.systemGray
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = .right
    }
}
