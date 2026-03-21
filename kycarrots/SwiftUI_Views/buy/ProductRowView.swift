import SwiftUI
import Kingfisher

struct ProductRowView: View {
    let item: AdItem
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Thumbnail Image
            if let urlString = item.imageUrl, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        Rectangle()
                            .fill(Color(.systemGray6))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .cornerRadius(12)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(width: 90, height: 90)
                    .cornerRadius(12)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(item.title ?? "제목 없음")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.label))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Price (Orange Color #FF6D00)
                if let priceString = item.price, let priceVal = Double(priceString) {
                    Text("\(formattedPrice(priceVal))원")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(red: 255/255, green: 109/255, blue: 0/255))
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    private func formattedPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(price))) ?? "0"
    }
}
