import Foundation
import Combine

final class ChatViewModel: ObservableObject {
    
    // MARK: - Inputs (from Coordinator/View Init)
    let roomId: String
    let currentUserId: String
    let otherId: String
    private let branchId: String // 본사 판별을 위해 저장
    
    // MARK: - State
    @Published var chatMessages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var isConnected: Bool = false
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var topicPath: String { "/topic/\(roomId)" }
    
    init(roomId: String, currentUserId: String, buyerId: String, branchId: String) {
        self.roomId = roomId
        self.currentUserId = currentUserId
        self.branchId = branchId // 저장
        
        // resolve otherId (Match Android resolveOtherId logic)
        let memberCode = LoginInfoUtil.getMemberCode()
        let branchName = LoginInfoUtil.getBranchName()
        print("🔍 ChatViewModel init - role: \(memberCode), branchName: '\(branchName)', branchId: '\(branchId)'")
        
        let resolvedName: String
        
        if memberCode == Constants.ROLE_PUB {
            resolvedName = branchName.isEmpty ? "지점" : branchName
        } else if memberCode == Constants.ROLE_PROJ {
            if branchId == Constants.CENTER_BRANCH_ID {
                resolvedName = "본사"
            } else {
                resolvedName = buyerId
            }
        } else if memberCode == Constants.ROLE_SELL {
            resolvedName = "\(buyerId) 지점"
        } else {
            resolvedName = buyerId // fallback
        }
        
        // Match Android title format
        self.otherId = "\(resolvedName) 님과의 대화"
        
        bindStomp()
    }
    
    deinit {
        StompManager.shared.sendExitRoom(roomId: roomId, userId: currentUserId)
        StompManager.shared.unsubscribe(topicPath: topicPath)
        StompManager.shared.disconnect()
    }
    
    // MARK: - STOMP Binding
    private func bindStomp() {
        let stomp = StompManager.shared
        
        stomp.onConnected = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isConnected = true
                stomp.subscribe(topicPath: self.topicPath)
                // 명시적 진입 신호
                stomp.sendEnterRoom(roomId: self.roomId, userId: self.currentUserId)
            }
        }
        
        stomp.onMessage = { [weak self] received in
            guard let self = self else { return }
            
            // 내가 보낸 메시지가 서버를 통해 다시 돌아온 경우 무시 (이미 sendMessage에서 로컬 추가함)
            if received.senderId == self.currentUserId { return }
            
            var msg = received
            msg.isMe = (received.senderGroup == LoginInfoUtil.getMemberCode())
            
            DispatchQueue.main.async {
                self.chatMessages.append(msg)
            }
        }
        
        stomp.onDisconnected = { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isConnected = false
            }
        }
    }
    
    func connect() {
        StompManager.shared.connect(userId: currentUserId)
    }
    
    func disconnect() {
        StompManager.shared.sendExitRoom(roomId: roomId, userId: currentUserId)
        StompManager.shared.unsubscribe(topicPath: topicPath)
        StompManager.shared.disconnect()
    }

    // MARK: - API Loading
    @MainActor
    func loadHistory() async {
        guard !roomId.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let responses = try await AppServiceProvider.shared.getChatMessages(roomId: roomId)
            self.chatMessages = responses.map { m in
                ChatMessage(
                    senderId: m.senderId,
                    message: m.message,
                    roomId: m.roomId,
                    type: "text",
                    time: m.time,
                    senderGroup: m.senderGroup,
                    receiveGroup: m.receiveGroup,
                    isMe: m.senderGroup == LoginInfoUtil.getMemberCode()
                )
            }
        } catch {
            print("❌ ChatViewModel loadHistory error: \(error)")
        }
    }
    
    // MARK: - Send
    func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let memberCode = LoginInfoUtil.getMemberCode()
        
        // 사용자 지정 규칙 반영
        let receiveGroup: String
        switch memberCode {
        case Constants.ROLE_PUB:
            receiveGroup = Constants.ROLE_PROJ
        case Constants.ROLE_SELL:
            receiveGroup = Constants.ROLE_PROJ
        case Constants.ROLE_PROJ:
            // 상대방이 본사('2')면 ROLE_SELL, 아니면 ROLE_PUB
            receiveGroup = (branchId == Constants.CENTER_BRANCH_ID) ? Constants.ROLE_SELL : Constants.ROLE_PUB
        default:
            receiveGroup = Constants.ROLE_PROJ
        }
        
        let now = Self.formatNow()
        let msg = ChatMessage(
            senderId: currentUserId,
            message: text,
            roomId: roomId,
            type: "text",
            time: now,
            senderGroup: memberCode,
            receiveGroup: receiveGroup,
            isMe: true
        )
        
        // Clear input
        messageText = ""
        
        // Add to list locally
        chatMessages.append(msg)
        
        // Send via STOMP
        StompManager.shared.sendRoomMessage(msg)
    }
    
    private static func formatNow() -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}
