import Foundation

/// 안드로이드 코드의 상태코드 기준으로 UI 라벨만 담당
/// (실제 API에는 saleStatus "1","10","99","98" 같은 코드가 넘어감)
enum SaleStatus: Int, CaseIterable, Identifiable {
    case rejected = 98      // 승인반려(또는 반려)
    case onSale  = 1        // 판매중
    case reserved = 10      // 예약중
    case soldOut = 99       // 판매완료

    var id: Int { self.rawValue }

    var title: String {
        switch self {
        case .rejected: return "승인반려"
        case .onSale:   return "판매중"
        case .reserved: return "예약중"
        case .soldOut:  return "판매완료"
        }
    }

    /// 서버에 넘길 saleStatus 코드
    var apiCode: String {
        switch self {
        case .rejected: return "0"   // 서버에서 반려가 98이면 "98"로 바꾸면 됨
        case .onSale:   return "1"
        case .reserved: return "10"
        case .soldOut:  return "99"
        }
    }
}
