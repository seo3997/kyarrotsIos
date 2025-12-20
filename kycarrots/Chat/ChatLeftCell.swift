//
//  ChatLeftCell.swift
//  kycarrots
//
//  Created by soo on 12/20/25.
//


import UIKit

final class ChatLeftCell: UITableViewCell {

    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        ChatBubbleStyle.applyLeft(bubbleView: bubbleView, messageLabel: messageLabel, timeLabel: timeLabel)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
    }

    func bind(_ msg: ChatMessage) {
        messageLabel.text = msg.message
        timeLabel.text = msg.time
    }
}
