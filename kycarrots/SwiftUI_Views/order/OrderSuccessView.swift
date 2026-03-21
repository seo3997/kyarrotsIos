import SwiftUI

struct OrderSuccessView: View {
    let orderId: String
    let orderNo: String
    let amount: Int
    var onGoHome: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // ── 1. 성공 아이콘 및 메시지 ──────────────────────────────
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 12) {
                    Text("주문이 완료되었습니다!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("주문해주셔서 감사합니다.\n상품 준비를 곧 시작할게요.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.bottom, 60)
            
            // ── 2. 주문 정보 요약 카드 ──────────────────────────────
            VStack(spacing: 16) {
                HStack {
                    Text("주문번호")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(orderNo.isEmpty ? orderId : orderNo)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Divider()
                
                HStack {
                    Text("결제금액")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // ── 3. 하단 버튼 ──────────────────────────────
            Button(action: onGoHome) {
                Text("홈으로 이동")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Color(white: 0.98).ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private func formatCurrency(_ value: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: NSNumber(value: value)) ?? "0원"
    }
}

struct OrderSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        OrderSuccessView(
            orderId: "123",
            orderNo: "ORD_20260322_00001",
            amount: 53000,
            onGoHome: {}
        )
    }
}
