import SwiftUI

struct ProductListSwiftUIView: View {
    @StateObject private var viewModel = ProductListViewModel()
    var onSelectProduct: ((AdItem) -> Void)?
    var onAddProduct: (() -> Void)? // 나중에 다시 사용할 수 있도록 유지
    var onShowNotifications: (() -> Void)?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Segmented Control (Tabs)
                Picker("상태", selection: $viewModel.selectedStatus) {
                    ForEach(SaleStatus.allCases, id: \.self) { status in
                        Text(status.title).tag(status)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: viewModel.selectedStatus) { _ in
                    viewModel.fetchProducts(isRefresh: true)
                }
                
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
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))
                .refreshable {
                    viewModel.fetchProducts(isRefresh: true)
                }
                
                if viewModel.items.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "square.dashed")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("해당 상태의 상품이 없습니다.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            /* ✅ 새상품 등록 버튼 (필요시 주석 해제하여 사용)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        onAddProduct?()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 3)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
            */
        }
        .navigationTitle("상품리스트")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NotificationBellButton(onTap: onShowNotifications)
            }
        }
        .navigationBarHidden(false) // ✅ 네비게이션 바 다시 표시 (상세에서 돌아올 때 복구)
        .navigationBarBackButtonHidden(true) // ✅ 뒤로가기 버튼 숨김 (사이드 메뉴만 표시)
        .onAppear {
            viewModel.fetchProducts(isRefresh: true)
        }
    }
}
