
import Foundation

/// String? → Int64? 안전 변환
/// - nil / "" / 숫자 아님 → nil
func stringToInt64(_ value: String?) -> Int64? {
    guard let s = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !s.isEmpty,
          let v = Int64(s) else {
        return nil
    }
    return v
}

func formatCommaNoDecimal(_ raw: String?) -> String {
    let s = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if s.isEmpty { return "-" }

    // "100000.00" 대응
    let d = Double(s) ?? 0
    let n = Int64(d.rounded(.towardZero))   // 소수점 버림

    let f = NumberFormatter()
    f.numberStyle = NumberFormatter.Style.decimal
    f.maximumFractionDigits = 0
    f.minimumFractionDigits = 0

    return f.string(from: NSNumber(value: n)) ?? "\(n)"
}

