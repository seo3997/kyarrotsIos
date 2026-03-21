import SwiftUI

struct OrderSuccessView: View {
    let orderNo: String
    let amount: Int
    var onGoHome: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
            
            Text("주문이 완료되었습니다!")
                .font(.system(size: 24, weight: .bold))
            
            VStack(spacing: 12) {
                HStack {
                    Text("주문번호")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(orderNo)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("결제금액")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(formattedAmount)
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(hex: "F8F9FA"))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            Text("신속하고 정확하게 배송해드리겠습니다.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: {
                onGoHome()
            }) {
                Text("홈으로 이동")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: NSNumber(value: amount)) ?? "0원"
    }
}
