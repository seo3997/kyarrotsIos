import SwiftUI

struct RangeSliderView: View {
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    var range: ClosedRange<Double>
    var step: Double = 5000
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack(alignment: .leading) {
                // 전체 배경 트랙
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                
                // 활성화된 범위 표시 트랙
                let lowerX = xForValue(lowerValue, in: width)
                let upperX = xForValue(upperValue, in: width)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: max(0, upperX - lowerX), height: 4)
                    .offset(x: lowerX)
                
                // 최소값 핸들
                ThumbView()
                    .offset(x: lowerX - 14)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newValue = valueForX(value.location.x, in: width)
                                let snappedValue = round(newValue / step) * step
                                lowerValue = min(max(range.lowerBound, snappedValue), upperValue)
                            }
                    )
                
                // 최대값 핸들
                ThumbView()
                    .offset(x: upperX - 14)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newValue = valueForX(value.location.x, in: width)
                                let snappedValue = round(newValue / step) * step
                                upperValue = max(min(range.upperBound, snappedValue), lowerValue)
                            }
                    )
            }
            .frame(height: height)
        }
        .frame(height: 32)
    }
    
    // 위치를 값으로 변환
    private func valueForX(_ x: CGFloat, in width: CGFloat) -> Double {
        let percentage = Double(max(0, min(x, width)) / width)
        return range.lowerBound + percentage * (range.upperBound - range.lowerBound)
    }
    
    // 값을 위치로 변환
    private func xForValue(_ value: Double, in width: CGFloat) -> CGFloat {
        let rangeWidth = range.upperBound - range.lowerBound
        guard rangeWidth > 0 else { return 0 }
        let percentage = (value - range.lowerBound) / rangeWidth
        return CGFloat(percentage) * width
    }
}

// 네이티브 슬라이더 핸들과 유사한 뷰
struct ThumbView: View {
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 28, height: 28)
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
            .overlay(
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
    }
}
