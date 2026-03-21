import SwiftUI
import Combine
import SideMenu

@MainActor
class MainTabViewModel: ObservableObject {
    @Published var unreadNotificationCount = 0
    
    func fetchUnreadCount() {
        let userId = LoginInfoUtil.getUserId()
        Task {
            let count = await NotificationBadgeHelper.fetchUnreadCount(userId: userId)
            await MainActor.run {
                self.unreadNotificationCount = count
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var viewModel = MainTabViewModel()
    @AppStorage(LoginInfoUtil.KEY_BRANCH_NAME) var branchNameValue: String = ""
    
    var onSelectProduct: ((AdItem) -> Void)? = nil
    var onSelectOrder: ((String) -> Void)? = nil
    var onShowNotifications: (() -> Void)? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onSelectProduct: onSelectProduct)
                .tabItem {
                    Label("홈", systemImage: "house")
                }
                .tag(0)
            
            InterestProductView(onSelectProduct: onSelectProduct)
                .tabItem {
                    Label("관심상품", systemImage: "heart")
                }
                .tag(1)
            
            PurchaseHistoryView(onSelectOrder: onSelectOrder)
                .tabItem {
                    Label("구매내역", systemImage: "bag")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    onShowNotifications?()
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                        
                        if viewModel.unreadNotificationCount > 0 {
                            Text("\(min(viewModel.unreadNotificationCount, 99))\(viewModel.unreadNotificationCount > 99 ? "+" : "")")
                                .font(.system(size: 9, weight: .bold))
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
        .navigationBarBackButtonHidden(true) // ✅ 뒤로가기 버튼 숨김
        .navigationBarHidden(false) // ✅ 네비게이션 바 다시 표시
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            let font = UIFont.systemFont(ofSize: 12, weight: .bold)
            
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .font: font,
                .foregroundColor: UIColor.systemGray
            ]
            appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
            
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .font: font,
                .foregroundColor: UIColor.systemBlue
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // 초기 데이터 로드
            viewModel.fetchUnreadCount()
        }
    }
    
    private var navigationTitle: String {
        let baseTitle: String
        switch selectedTab {
        case 0: baseTitle = "상품리스트"
        case 1: baseTitle = "관심상품"
        case 2: baseTitle = "구매내역"
        default: baseTitle = ""
        }
        
        let displayBranch = branchNameValue.isEmpty ? LoginInfoUtil.getBranchName() : branchNameValue
        
        if !displayBranch.isEmpty {
            return "(\(displayBranch)) \(baseTitle)"
        } else {
            return baseTitle
        }
    }
}
