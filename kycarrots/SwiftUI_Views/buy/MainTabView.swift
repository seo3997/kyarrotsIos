import SwiftUI
import SideMenu

struct MainTabView: View {
    @State private var selectedTab = 0
    var onSelectProduct: ((AdItem) -> Void)? = nil
    
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
            
            PurchaseHistoryView(onSelectProduct: onSelectProduct)
                .tabItem {
                    Label("구매내역", systemImage: "bag")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if let menuNav = SideMenuManager.default.leftMenuNavigationController {
                        UIApplication.shared.windows.first?.rootViewController?.present(menuNav, animated: true)
                    }
                }) {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
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
        }
    }
}
