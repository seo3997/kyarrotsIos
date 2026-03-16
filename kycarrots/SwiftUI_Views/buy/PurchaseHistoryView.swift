import SwiftUI

struct PurchaseHistoryView: View {
    @StateObject private var viewModel = PurchaseHistoryViewModel()
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
                            viewModel.fetchPurchaseList()
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                viewModel.fetchPurchaseList(isRefresh: true)
            }
            
            if viewModel.items.isEmpty && !viewModel.isLoading {
                Text("구매내역이 없습니다.")
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.fetchPurchaseList(isRefresh: true)
        }
    }
}
