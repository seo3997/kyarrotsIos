import Foundation

/// 안드로이드 MainActivity.kr 기준 SaleStatus 매핑
/// (반려 항목 제거 및 상태 코드 업데이트)
enum SaleStatus: Int, CaseIterable, Identifiable {
    case onSale = 0      // 판매중 ("1")
    case outOfStock = 1  // 품절 ("20")
    case suspended = 2   // 판매중지 ("30")
    case completed = 3   // 판매완료 ("99")

    var id: Int { self.rawValue }

    var title: String {
        switch self {
        case .onSale:      return "판매중"
        case .outOfStock:  return "품절"
        case .suspended:   return "판매중지"
        case .completed:   return "판매완료"
        }
    }

    /// 서버에 넘길 saleStatus 코드
    var apiCode: String {
        switch self {
        case .onSale:      return "1"
        case .outOfStock:  return "20"
        case .suspended:   return "30"
        case .completed:   return "99"
        }
    }
}
