import SwiftUI
import Kingfisher

struct DashboardSwiftUIView: View {
    @StateObject private var viewModel = DashboardViewModel()
    var onShowNotifications: (() -> Void)?
    var onAddProduct: (() -> Void)?
    var onSelectProduct: ((RecentProductViewModel) -> Void)?
    var onShowMore: (() -> Void)?
    var onShowApproval: (() -> Void)?
    
    @State private var showingWholesalerPicker = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Stats Card
                    VStack(spacing: 12) {
                        HStack {
                            Text("총 등록 매물: \(viewModel.totalProducts)건")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("승인반려: \(viewModel.rejectedCount)건 / 처리 중: \(viewModel.processingCount)건 / 완료: \(viewModel.completedCount)건")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        if LoginInfoUtil.getMemberCode() == "ROLE_SELL" || LoginInfoUtil.getMemberCode() == "ROLE_PROJ" {
                            Button(action: {
                                viewModel.checkWholesalerAndMove {
                                    onAddProduct?()
                                } onShowPicker: { _ in
                                    showingWholesalerPicker = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("매물 등록하기")
                                }
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                        
                        if Constants.SYSTEM_TYPE == 2 {
                            Button(action: {
                                onShowApproval?()
                            }) {
                                Text("승인/처리 화면")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Products Title & More
                    HStack {
                        Text("최근 등록된 매물")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Button(action: {
                            onShowMore?()
                        }) {
                            Text("더보기")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Recent Products List
                    VStack(spacing: 12) {
                        if viewModel.recentProducts.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "list.bullet.rectangle.portrait")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("최근 등록된 매물이 없습니다.")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        } else {
                            ForEach(viewModel.recentProducts, id: \.productId) { item in
                                RecentProductRowView(item: item) {
                                    onSelectProduct?(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .refreshable {
                viewModel.fetchDashboardData()
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("대시보드")
        .navigationBarTitleDisplayMode(.inline)
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
        .actionSheet(isPresented: $showingWholesalerPicker) {
            ActionSheet(
                title: Text("센터/도매상 선택"),
                buttons: viewModel.wholesalers.map { wholesaler in
                    .default(Text("\(wholesaler.userNm ?? "")(\(wholesaler.userNo ?? "0"))")) {
                        viewModel.setSelectedWholesaler(wholesaler.userNo ?? "") {
                            onAddProduct?()
                        }
                    }
                } + [.cancel(Text("취소"))]
            )
        }
        .navigationBarHidden(false) // ✅ 네비게이션 바 다시 표시 (상세에서 돌아올 때 복구)
        .navigationBarBackButtonHidden(true) // ✅ 뒤로가기 버튼 숨김
        .onAppear {
            viewModel.fetchDashboardData()
            viewModel.fetchUnreadCount()
        }
    }
}

struct RecentProductRowView: View {
    let item: RecentProductViewModel
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primary)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.subInfo)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let status = item.statusName {
                    Text(status)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.10, green: 0.14, blue: 0.49)) // #1A237E
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
