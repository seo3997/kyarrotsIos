//
//  ProductTableViewCell.swift
//  kycarrots
//
//  Created by soohyun on 11/22/25.
//

import UIKit
import Kingfisher

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
    
     //  - 필드 이름은 Android/백엔드 DTO와 동일하다고 가정 (필요 시 이름만 수정)
    func configure(with item: AdItem) {
        // 상품명
        titleLabel.text = item.title
        briefLabel.text = item.description

        // 썸네일 이미지
        if let urlString = item.imageUrl,
           let url = URL(string: urlString) {

            thumbImageView.kf.indicatorType = .activity  // 로딩 스피너
            thumbImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholder"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )

        } else {
            thumbImageView.image = UIImage(named: "placeholder")
        }
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
