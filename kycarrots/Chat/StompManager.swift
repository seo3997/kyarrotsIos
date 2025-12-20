import Foundation
import Starscream

final class StompManager {

    static let shared = StompManager()
    private init() {}

    private var socket: WebSocket?
    private(set) var isConnected: Bool = false

    // topicPath -> subscriptionId
    private var subscriptions: [String: String] = [:]
    private var pendingSubscribeTopicPaths: [String] = [] // CONNECTED 오기 전 호출 대비

    // 콜백
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    var onMessage: ((ChatMessage) -> Void)?

    // MARK: - Connect / Disconnect

    func connect(userId: String) {
        if isConnected { return }

        let url = Constants.wsURL(userId: userId)
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let ws = WebSocket(request: request)
        ws.onEvent = { [weak self] event in
            self?.handleEvent(event)
        }

        socket = ws
        ws.connect()
    }

    func disconnect() {
        // 가능하면 서버에 unsubscribe를 보내고 종료
        for (topic, subId) in subscriptions {
            _ = topic
            socket?.write(string: StompFrame.unsubscribe(id: subId))
        }
        subscriptions.removeAll()
        pendingSubscribeTopicPaths.removeAll()

        socket?.disconnect()
        socket = nil
        isConnected = false
    }

    // MARK: - Subscribe / Unsubscribe

    /// ChatVC에서 쓰는 형태: topicPath = "/topic/{roomId}"
    func subscribe(topicPath: String) {
        // 이미 구독 중이면 무시
        if subscriptions[topicPath] != nil { return }

        // CONNECTED 오기 전에 호출되면 대기열에 넣었다가 연결 후 처리
        if !isConnected {
            if !pendingSubscribeTopicPaths.contains(topicPath) {
                pendingSubscribeTopicPaths.append(topicPath)
            }
            return
        }

        let subId = UUID().uuidString
        subscriptions[topicPath] = subId
        socket?.write(string: StompFrame.subscribe(id: subId, destination: topicPath))
    }

    func unsubscribe(topicPath: String) {
        guard let subId = subscriptions.removeValue(forKey: topicPath) else { return }
        socket?.write(string: StompFrame.unsubscribe(id: subId))
    }

    // MARK: - Send

    func sendRoomMessage(_ message: ChatMessage) {
        guard isConnected else { return }

        // 서버에 isMe는 보통 필요 없으므로 nil로 보내는 게 깔끔
        var payload = message
        payload.isMe = nil

        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8)
        else { return }

        let destination = "/app/chat.send.\(message.roomId)"
        socket?.write(string: StompFrame.send(destination: destination, body: json))
    }

    // MARK: - WebSocket Event Handling

    private func handleEvent(_ event: WebSocketEvent) {
        switch event {

        case .connected:
            // WebSocket 레벨 연결됨 -> STOMP CONNECT 보내기
            socket?.write(string: StompFrame.connect())

        case .text(let text):
            handleIncomingText(text)

        case .binary(let data):
            // 서버가 binary로 올 수도 있어 방어
            if let text = String(data: data, encoding: .utf8) {
                handleIncomingText(text)
            }

        case .disconnected(_, _):
            let was = isConnected
            isConnected = false
            if was {
                onDisconnected?(nil)
            }

        case .error(let err):
            let was = isConnected
            isConnected = false
            onDisconnected?(err)
            if was == false {
                // 연결 중 에러
            }

        default:
            break
        }
    }

    private func handleIncomingText(_ text: String) {
        // STOMP는 \u{0000} null로 frame delimiter가 올 수 있음
        // 여러 프레임이 한번에 올 수도 있으니 split
        let frames = text.split(separator: "\u{0000}", omittingEmptySubsequences: true)
        for raw in frames {
            parseFrame(String(raw))
        }
    }

    private func parseFrame(_ raw: String) {
        // STOMP frame 기본:
        // COMMAND\n
        // header:val\n
        // ...\n
        // \n
        // body...
        let parts = raw.components(separatedBy: "\n\n")
        guard let head = parts.first else { return }

        let headLines = head.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard let command = headLines.first else { return }

        // body
        let body = parts.count >= 2 ? parts[1] : ""

        switch command {
        case "CONNECTED":
            isConnected = true
            onConnected?()

            // CONNECTED 이후 대기 중이던 구독 처리
            if !pendingSubscribeTopicPaths.isEmpty {
                let pending = pendingSubscribeTopicPaths
                pendingSubscribeTopicPaths.removeAll()
                pending.forEach { subscribe(topicPath: $0) }
            }

        case "MESSAGE":
            // MESSAGE body는 JSON(ChatMessage)로 온다고 가정
            guard let data = body.data(using: .utf8) else { return }
            if var msg = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                // isMe는 UI에서 정함
                msg.isMe = nil
                onMessage?(msg)
            }

        case "ERROR":
            // 서버 STOMP 에러
            let err = NSError(domain: "STOMP", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "STOMP ERROR: \(body)"
            ])
            onDisconnected?(err)

        default:
            // RECEIPT 등 무시
            break
        }
    }
}
