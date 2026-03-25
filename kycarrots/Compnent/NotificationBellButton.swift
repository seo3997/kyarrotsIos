import SwiftUI
import Combine

class NotificationBellViewModel: ObservableObject {
    @Published var unreadCount: Int = 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchCount()
        
        // 실시간 업데이트 구독
        NotificationCenter.default.publisher(for: .didReceiveNewPush)
            .sink { [weak self] _ in
                self?.fetchCount()
            }
            .store(in: &cancellables)
    }
    
    func fetchCount() {
        let userId = LoginInfoUtil.getUserId()
        guard !userId.isEmpty else { return }
        
        Task {
            let count = await NotificationBadgeHelper.fetchUnreadCount(userId: userId)
            await MainActor.run {
                self.unreadCount = count
            }
        }
    }
}

struct NotificationBellButton: View {
    @StateObject private var viewModel = NotificationBellViewModel()
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            Image(systemName: "bell")
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .overlay(alignment: .topTrailing) {
                    if viewModel.unreadCount > 0 {
                        Text("\(min(viewModel.unreadCount, 99))")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(3)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
        }
        .onAppear {
            viewModel.fetchCount()
        }
    }
}
