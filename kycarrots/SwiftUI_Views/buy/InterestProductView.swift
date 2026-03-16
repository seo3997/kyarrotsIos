import SwiftUI
import Kingfisher

struct InterestProductView: View {
    @StateObject private var viewModel = InterestProductViewModel()
    var onSelectProduct: ((AdItem) -> Void)? = nil
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.items, id: \.productId) { item in
                    Button(action: {
                        onSelectProduct?(item)
                    }) {
                        ProductRowView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if item.productId == viewModel.items.last?.productId {
                            viewModel.fetchInterestList()
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                viewModel.fetchInterestList(isRefresh: true)
            }
            
            if viewModel.items.isEmpty && !viewModel.isLoading {
                Text("관심상품이 없습니다.")
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.fetchInterestList(isRefresh: true)
        }
    }
}
