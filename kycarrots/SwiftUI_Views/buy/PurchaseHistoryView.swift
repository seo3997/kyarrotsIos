import SwiftUI

struct PurchaseHistoryView: View {
    @StateObject private var viewModel = PurchaseHistoryViewModel()
    var onSelectProduct: ((AdItem) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
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
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .refreshable {
                viewModel.fetchPurchaseList(isRefresh: true)
            }
            
            if viewModel.items.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "cart.badge.minus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("구매내역이 없습니다.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .onAppear {
            if viewModel.items.isEmpty {
                viewModel.fetchPurchaseList(isRefresh: true)
            }
        }
    }
}
