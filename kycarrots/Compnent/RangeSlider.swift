import UIKit

class RangeSlider: UIControl {
    private let trackLayer = CALayer()
    private let rangeTrackLayer = CALayer()
    private let lowerThumbImageView = UIImageView()
    private let upperThumbImageView = UIImageView()
    
    // 핸들 크기 및 여백 설정
    private let thumbSize: CGFloat = 30
    private var thumbPadding: CGFloat { return thumbSize / 2 } // 양옆 여백 확보
    
    var minimumValue: CGFloat = 0 { didSet { updateLayerFrames() } }
    var maximumValue: CGFloat = 9990000 { didSet { updateLayerFrames() } }
    var lowerValue: CGFloat = 0 { didSet { updateLayerFrames() } }
    var upperValue: CGFloat = 9990000 { didSet { updateLayerFrames() } }
    
    private var previousLocation = CGPoint()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSlider()
    }
    
    private func setupSlider() {
        // 잘림 방지 설정
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        
        trackLayer.backgroundColor = UIColor.systemGray5.cgColor
        layer.addSublayer(trackLayer)
        
        rangeTrackLayer.backgroundColor = UIColor.systemBlue.cgColor
        layer.addSublayer(rangeTrackLayer)
        
        let thumbImage = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        
        [lowerThumbImageView, upperThumbImageView].forEach {
            $0.image = thumbImage
            $0.contentMode = .scaleAspectFit
            // 그림자가 아래로 살짝 내려오도록 설정하여 입체감 부여
            $0.layer.shadowRadius = 3
            $0.layer.shadowOpacity = 0.25
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
            addSubview($0)
        }
        
        updateLayerFrames()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }
    
    func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 애니메이션 끊김 방지
        
        let trackHeight: CGFloat = 4.0
        let trackY = (bounds.height - trackHeight) / 2
        
        // 1. 트랙 프레임 (양옆 thumbPadding만큼 여백을 주어 핸들이 밖으로 나가지 않게 함)
        trackLayer.frame = CGRect(x: thumbPadding, y: trackY, width: bounds.width - (thumbPadding * 2), height: trackHeight)
        trackLayer.cornerRadius = trackHeight / 2
        
        let lowerThumbCenter = positionForValue(lowerValue)
        let upperThumbCenter = positionForValue(upperValue)
        
        // 2. 파란색 선택 범위 트랙
        rangeTrackLayer.frame = CGRect(x: lowerThumbCenter,
                                       y: trackY,
                                       width: upperThumbCenter - lowerThumbCenter,
                                       height: trackHeight)
        rangeTrackLayer.cornerRadius = trackHeight / 2
        
        // 3. 핸들 위치 (y값을 뷰의 중앙에 정확히 배치)
        let thumbY = (bounds.height - thumbSize) / 2
        
        lowerThumbImageView.frame = CGRect(x: lowerThumbCenter - thumbPadding,
                                           y: thumbY,
                                           width: thumbSize,
                                           height: thumbSize)
        
        upperThumbImageView.frame = CGRect(x: upperThumbCenter - thumbPadding,
                                           y: thumbY,
                                           width: thumbSize,
                                           height: thumbSize)
        
        CATransaction.commit()
    }
    
    // 핸들이 움직이는 가용 범위를 (0 ~ 너비)가 아니라 (여백 ~ 너비-여백)으로 수정
    private func positionForValue(_ value: CGFloat) -> CGFloat {
        let usableWidth = bounds.width - (thumbPadding * 2)
        return usableWidth * (value - minimumValue) / (maximumValue - minimumValue) + thumbPadding
    }
    
    override func beginTracking(_ touch: UITouch?, with event: UIEvent?) -> Bool {
        guard let touch = touch else { return false }
        previousLocation = touch.location(in: self)
        
        if lowerThumbImageView.frame.contains(previousLocation) {
            lowerThumbImageView.isHighlighted = true
        } else if upperThumbImageView.frame.contains(previousLocation) {
            upperThumbImageView.isHighlighted = true
        }
        return lowerThumbImageView.isHighlighted || upperThumbImageView.isHighlighted
    }
    
    override func continueTracking(_ touch: UITouch?, with event: UIEvent?) -> Bool {
        guard let touch = touch else { return false }
        let location = touch.location(in: self)
        
        let deltaLocation = location.x - previousLocation.x
        let usableWidth = bounds.width - (thumbPadding * 2)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / usableWidth
        
        previousLocation = location
        
        if lowerThumbImageView.isHighlighted {
            lowerValue = min(max(lowerValue + deltaValue, minimumValue), upperValue)
        } else if upperThumbImageView.isHighlighted {
            upperValue = min(max(upperValue + deltaValue, lowerValue), maximumValue)
        }
        
        sendActions(for: .valueChanged)
        updateLayerFrames()
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbImageView.isHighlighted = false
        upperThumbImageView.isHighlighted = false
    }
}
