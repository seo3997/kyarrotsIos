import SwiftUI
import Combine
import CoreData

@MainActor
class NotificationListViewModel: ObservableObject {
    @Published var items: [PushNotification] = []
    @Published var isLoading = false
    
    private let repo: PushRepository
    private let userIdProvider: () -> String?
    
    init(
        repo: PushRepository = CoreDataPushRepository(),
        userIdProvider: @escaping () -> String? = { UserDefaults.standard.string(forKey: "LogIn_ID") }
    ) {
        self.repo = repo
        self.userIdProvider = userIdProvider
    }
    
    func markAllReadAndReload() {
        guard let userId = userIdProvider(), !userId.isEmpty else { return }
        
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.repo.markAllRead(userId: userId)
                let rows = try self.repo.list(userId: userId, onlyUnread: false, limit: 100, offset: 0)
                
                DispatchQueue.main.async {
                    self.items = rows
                    self.isLoading = false
                    // Update global badge count if needed
                }
            } catch {
                print("Notification load failed: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func deleteOne(_ item: PushNotification) {
        do {
            try repo.delete(id: item.id)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items.remove(at: index)
            }
        } catch {
            print("Delete failed: \(error)")
        }
    }
    
    func markRead(_ item: PushNotification) {
        do {
            try repo.markRead(id: item.id)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].isRead = true
            }
        } catch {
            print("Mark read failed: \(error)")
        }
    }
}

struct NotificationListSwiftUIView: View {
    @StateObject var viewModel: NotificationListViewModel
    var onSelectNotification: (PushNotification) -> Void
    
    var body: some View {
        ZStack {
            if viewModel.items.isEmpty && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("알림이 없습니다.")
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    ForEach(viewModel.items, id: \.id) { item in
                        NotificationRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.markRead(item)
                                onSelectNotification(item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteOne(item)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("알림 리스트")
        .navigationBarHidden(false) // ✅ 네비게이션 바 명시적 표시
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("전체읽음") {
                    viewModel.markAllReadAndReload()
                }
            }
        }
        .onAppear {
            viewModel.markAllReadAndReload()
        }
    }
}

struct NotificationRow: View {
    let item: PushNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .opacity(item.isRead ? 0.15 : 1.0)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let body = item.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("\(item.type) · \(format(item.createdAt))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private func format(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f.string(from: d)
    }
}
