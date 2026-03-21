import SwiftUI

struct InterestProductView: View {
    @StateObject private var viewModel = InterestProductViewModel()
    var onSelectProduct: ((AdItem) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (옵션: 필요 시 추가 가능)
            
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
                                viewModel.fetchInterestList()
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
                viewModel.fetchInterestList(isRefresh: true)
            }
            
            if viewModel.items.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("관심상품이 없습니다.")
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
                viewModel.fetchInterestList(isRefresh: true)
            }
        }
    }
}
