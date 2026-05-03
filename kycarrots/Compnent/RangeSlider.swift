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
    var maximumValue: CGFloat = 999000 { didSet { updateLayerFrames() } }
    var lowerValue: CGFloat = 0 { didSet { updateLayerFrames() } }
    var upperValue: CGFloat = 999000 { didSet { updateLayerFrames() } }
    var step: CGFloat = 1000 { didSet { updateLayerFrames() } }
    
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
        self.isUserInteractionEnabled = true
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
            $0.isUserInteractionEnabled = false // 제스처가 부모(self)에서 처리되도록 함
            // 그림자가 아래로 살짝 내려오도록 설정하여 입체감 부여
            $0.layer.shadowRadius = 3
            $0.layer.shadowOpacity = 0.25
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
            addSubview($0)
        }
        
        // 터치 처리를 위해 PanGestureRecognizer 추가 (UIControl Tracking보다 SwiftUI에서 안정적)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
        
        updateLayerFrames()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            let touchAreaInset: CGFloat = -20
            if lowerThumbImageView.frame.insetBy(dx: touchAreaInset, dy: touchAreaInset).contains(location) {
                lowerThumbImageView.isHighlighted = true
            } else if upperThumbImageView.frame.insetBy(dx: touchAreaInset, dy: touchAreaInset).contains(location) {
                upperThumbImageView.isHighlighted = true
            }
            previousLocation = location
            
        case .changed:
            let deltaLocation = location.x - previousLocation.x
            let usableWidth = bounds.width - (thumbPadding * 2)
            guard usableWidth > 0 else { return }
            
            let deltaValue = (maximumValue - minimumValue) * deltaLocation / usableWidth
            
            if lowerThumbImageView.isHighlighted {
                let newValue = lowerValue + deltaValue
                lowerValue = min(max(round(newValue / step) * step, minimumValue), upperValue)
            } else if upperThumbImageView.isHighlighted {
                let newValue = upperValue + deltaValue
                upperValue = min(max(round(newValue / step) * step, lowerValue), maximumValue)
            }
            
            previousLocation = location
            sendActions(for: .valueChanged)
            
        case .ended, .cancelled:
            lowerThumbImageView.isHighlighted = false
            upperThumbImageView.isHighlighted = false
            
        default:
            break
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 40)
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
        
        // 트랙 프레임
        trackLayer.frame = CGRect(x: thumbPadding, y: trackY, width: max(0, bounds.width - (thumbPadding * 2)), height: trackHeight)
        trackLayer.cornerRadius = trackHeight / 2
        
        let lowerThumbCenter = positionForValue(lowerValue)
        let upperThumbCenter = positionForValue(upperValue)
        
        // 파란색 선택 범위 트랙
        rangeTrackLayer.frame = CGRect(x: lowerThumbCenter,
                                       y: trackY,
                                       width: max(0, upperThumbCenter - lowerThumbCenter),
                                       height: trackHeight)
        rangeTrackLayer.cornerRadius = trackHeight / 2
        
        // 핸들 위치
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
    
    private func positionForValue(_ value: CGFloat) -> CGFloat {
        let usableWidth = bounds.width - (thumbPadding * 2)
        guard usableWidth > 0 else { return thumbPadding }
        return usableWidth * (value - minimumValue) / (maximumValue - minimumValue) + thumbPadding
    }
}

// MARK: - SwiftUI Wrapper
import SwiftUI

struct RangeSliderView: UIViewRepresentable {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    var minimumValue: Double
    var maximumValue: Double
    var step: Double = 1000
    
    func makeUIView(context: Context) -> RangeSlider {
        let slider = RangeSlider()
        slider.minimumValue = CGFloat(minimumValue)
        slider.maximumValue = CGFloat(maximumValue)
        slider.lowerValue = CGFloat(lowerValue)
        slider.upperValue = CGFloat(upperValue)
        slider.step = CGFloat(step)
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return slider
    }
    
    func updateUIView(_ uiView: RangeSlider, context: Context) {
        // 사용자가 슬라이더를 조작 중(드래그 중)일 때는 외부에서의 값 업데이트를 중단하여 충돌 방지
        guard !uiView.isTracking else { return }
        
        // 소수점 차이로 인한 무한 루프 방지를 위해 값이 다를 때만 업데이트
        if abs(uiView.lowerValue - CGFloat(lowerValue)) > 1.0 {
            uiView.lowerValue = CGFloat(lowerValue)
        }
        if abs(uiView.upperValue - CGFloat(upperValue)) > 1.0 {
            uiView.upperValue = CGFloat(upperValue)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: RangeSliderView
        
        init(_ parent: RangeSliderView) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: RangeSlider) {
            parent.lowerValue = Double(sender.lowerValue)
            parent.upperValue = Double(sender.upperValue)
        }
    }
}
