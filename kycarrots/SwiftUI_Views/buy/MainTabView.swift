import SwiftUI
import Combine
import SideMenu

@MainActor
class MainTabViewModel: ObservableObject {
    // No longer needs unreadNotificationCount
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
                NotificationBellButton(onTap: onShowNotifications)
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
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
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
