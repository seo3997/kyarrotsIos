import SwiftUI
import Kingfisher

struct ProductRowView: View {
    let item: AdItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail Image
            if let urlString = item.imageUrl, let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                            .scaledToFill()
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(6)
                    .clipped()
            } else {
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(6)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? "제목 없음")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(item.description ?? "설명 없음")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                if let price = item.price {
                    Text("\(price)원")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.top, 30)
        }
        .padding(.vertical, 8)
    }
}
