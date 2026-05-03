import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    var onSelectProduct: ((AdItem) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Section
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // 판매중 필터
                    FilterChip(title: "판매중", isOn: $viewModel.isSaleOnly) {
                        viewModel.loadInitialData()
                    }
                    
                    // 단가조회 필터
                    FilterChip(title: "단가조회", isOn: $viewModel.isPriceFilterOn) {
                        if !viewModel.isPriceFilterOn {
                            viewModel.loadInitialData()
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // 가격 검색 슬라이더 영역
                if viewModel.isPriceFilterOn {
                    VStack(spacing: 14) {
                        HStack {
                            Text("희망단가")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text("\(CurrencyUtil.formatCurrency(Int(viewModel.minPrice))) ~ \(CurrencyUtil.formatCurrency(Int(viewModel.maxPrice)))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        RangeSliderView(
                            lowerValue: $viewModel.minPrice,
                            upperValue: $viewModel.maxPrice,
                            minimumValue: 0,
                            maximumValue: 999000,
                            step: 1000
                        )
                        .frame(height: 40)
                        
                        Button(action: {
                            viewModel.loadInitialData()
                        }) {
                            Text("조건으로 조회")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            .zIndex(1) // 필터 영역이 리스트 위에 뜨게 함

            // Product List
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
                                viewModel.fetchProducts()
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
                viewModel.loadInitialData()
            }
            
            if viewModel.items.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("검색된 상품이 없습니다.")
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
                viewModel.loadInitialData()
            }
        }
    }
}

// 헬퍼 뷰: 필터 칩 스타일
struct FilterChip: View {
    let title: String
    @Binding var isOn: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                isOn.toggle()
            }
            action()
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isOn ? Color.blue : Color(.systemGray6))
            .foregroundColor(isOn ? .white : .primary)
            .cornerRadius(20)
        }
    }
}
