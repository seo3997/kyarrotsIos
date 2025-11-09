import UIKit

final class RecentProductCell: UITableViewCell {
    static let reuseID = "RecentProductCell"
    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    // VC로 버튼 탭 이벤트 전달
    var onTapButton: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = .systemGroupedBackground
        contentView.backgroundColor = .systemGroupedBackground

        // 스토리보드에서 런타임 속성 안 줬다면 코드로 보정
        setupShadowIfNeeded()
        setupCardIfNeeded()
        setupIcon()
        setupButton()
    }

    private func setupShadowIfNeeded() {
        guard let c = shadowContainer else { return }
        c.backgroundColor = .clear
        c.layer.masksToBounds = false
        if c.layer.shadowOpacity == 0 {
            c.layer.shadowColor = UIColor.black.cgColor
            c.layer.shadowOpacity = 0.08
            c.layer.shadowRadius = 6
            c.layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }

    private func setupCardIfNeeded() {
        guard let v = cardView else { return }
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        if v.layer.borderWidth == 0 {
            v.layer.borderWidth = 1
            v.layer.borderColor = UIColor(white: 0.87, alpha: 1).cgColor // #DDDDDD
        }
    }

    private func setupIcon() {
        iconImageView.image = UIImage(systemName: "checkmark.circle.fill")
        iconImageView.tintColor = .label
    }

    private func setupButton() {
        actionButton.setTitle("승인요청", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        actionButton.backgroundColor = UIColor(red: 0.10, green: 0.14, blue: 0.49, alpha: 1) // #1A237E
        actionButton.layer.cornerRadius = 8
        actionButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
    }

    @objc private func tapButton() { onTapButton?() }

    func configure(title: String, subInfo: String) {
        titleLabel.text = title
        subLabel.text = subInfo
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapButton = nil
    }
}
