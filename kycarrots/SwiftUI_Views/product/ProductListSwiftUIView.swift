import SwiftUI

struct ProductListSwiftUIView: View {
    @StateObject private var viewModel = ProductListViewModel()
    var onSelectProduct: ((AdItem) -> Void)?
    var onAddProduct: (() -> Void)?
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
                                    viewModel.fetchProducts()
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.fetchProducts(isRefresh: true)
                    }
                    
                    if viewModel.items.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "square.dashed")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("해당 상태의 상품이 없습니다.")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.isLoading && viewModel.items.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
            
            // Floating Action Button
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
        }
        .navigationTitle("내 등록 매물")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    onShowNotifications?()
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                        
                        if viewModel.unreadNotificationCount > 0 {
                            Text("\(min(viewModel.unreadNotificationCount, 99))\(viewModel.unreadNotificationCount > 99 ? "+" : "")")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true) // ✅ 뒤로가기 버튼 숨김 (사이드 메뉴만 표시)
        .onAppear {
            viewModel.fetchProducts(isRefresh: true)
            viewModel.fetchUnreadCount()
        }
    }
}
