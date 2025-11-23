//
//  ProductTableViewCell.swift
//  kycarrots
//
//  Created by soohyun on 11/22/25.
//

import UIKit

class ProductTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ProductTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var briefLabel: UILabel!
    @IBOutlet weak var thumbImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 6
    }
    
    func configure(with item: Product) {
        titleLabel.text = item.name
        let priceText = "₩\(item.price.formatted())"
        let statusText = item.status.title
        briefLabel.text = "\(priceText) • \(statusText)"
        thumbImageView.image = UIImage(named: "placeholder")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
