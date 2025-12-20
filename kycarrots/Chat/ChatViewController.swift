import UIKit

final class ChatViewController: UIViewController {

    // MARK: - Storyboard Outlets
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBarBottom: NSLayoutConstraint! // inputBar.bottom = SafeArea.bottom

    // MARK: - Inputs
    var roomId: String!
    var buyerId: String!
    var sellerId: String!
    var productId: String!
    var currentUserId: String! // 로그인 ID

    // MARK: - State
    private var otherId: String = ""
    private var chatMessages: [ChatMessage] = []
    private var topicPath: String { "/topic/\(roomId!)" }

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTapToDismissKeyboard()
        validateInputsOrPop()

        setupUI()
        setupTable()
        chatTableView.rowHeight = UITableView.automaticDimension
        chatTableView.estimatedRowHeight = 60
        
        setupKeyboardHandling()

        resolveOtherId()
        title = "\(otherId) 님과의 대화"
        loadChatMessages(roomId: roomId)
        bindStompCallbacks()
        connectAndSubscribe()
    }
    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false   // ✅ 셀 터치/스크롤 방해하지 않게
        chatTableView.addGestureRecognizer(tap) // 또는 view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        StompManager.shared.unsubscribe(topicPath: topicPath)
        StompManager.shared.disconnect()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        sendButton.setTitle("전송", for: .normal)

        messageTextField.placeholder = "메시지를 입력하세요"
        messageTextField.returnKeyType = .send
        messageTextField.delegate = self
    }

    private func setupTable() {
        chatTableView.dataSource = self
        chatTableView.delegate = self

        chatTableView.keyboardDismissMode = .interactive
        chatTableView.separatorStyle = .none
        chatTableView.rowHeight = UITableView.automaticDimension
        chatTableView.estimatedRowHeight = 52
    }

    // MARK: - Keyboard
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ noti: Notification) {
        guard
            let info = noti.userInfo,
            let endFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let endFrameInView = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - endFrameInView.minY)
        let keyboardHeight = max(0, overlap - view.safeAreaInsets.bottom)

        inputBarBottom.constant = keyboardHeight

        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: false)
        }
    }

    // MARK: - Validate
    private func validateInputsOrPop() {
        guard roomId != nil, !roomId.isEmpty,
              buyerId != nil, !buyerId.isEmpty,
              sellerId != nil, !sellerId.isEmpty,
              productId != nil, !productId.isEmpty,
              currentUserId != nil, !currentUserId.isEmpty
        else {
            navigationController?.popViewController(animated: true)
            return
        }
    }

    // MARK: - OtherId
    private func resolveOtherId() {
        let myId = currentUserId!

        if myId == buyerId { otherId = sellerId }
        else if myId == sellerId { otherId = buyerId }
        else { otherId = [buyerId!, sellerId!].first(where: { $0 != myId }) ?? sellerId! }
    }

    // MARK: - STOMP
    private func bindStompCallbacks() {
        let stomp = StompManager.shared

        stomp.onConnected = { [weak self] in
            guard let self else { return }
            print("✅ STOMP connected! subscribe => \(self.topicPath)")
            stomp.subscribe(topicPath: self.topicPath)
        }

        stomp.onMessage = { [weak self] received in
            guard let self else { return }
            print("📩 STOMP recv: sender=\(received.senderId ?? "nil") room=\(received.roomId ?? "nil") msg=\(received.message)")
      
            // 내가 보낸 메시지는 서버에서 다시 오면 중복 방지
            if received.senderId == self.currentUserId { return }

            var msg = received
            msg.isMe = false

            DispatchQueue.main.async {
                self.chatMessages.append(msg)
                self.chatTableView.reloadData()
                self.scrollToBottom(animated: true)
            }
        }

        stomp.onDisconnected = { err in
            if let err { print("❌ STOMP disconnected:", err.localizedDescription) }
        }
    }

    private func connectAndSubscribe() {
        print("🔌 STOMP connect() try. userId=\(currentUserId ?? "nil") roomId=\(roomId ?? "nil") topic=\(topicPath)")
        StompManager.shared.connect(userId: currentUserId)
    }

    // MARK: - Actions
    @IBAction func tapSend(_ sender: Any) {
        sendCurrentText()
    }

    private func sendCurrentText() {
        let text = (messageTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let now = Self.formatNow()

        var msg = ChatMessage(
            senderId: currentUserId,
            message: text,
            roomId: roomId,
            type: "text",
            time: now,
            isMe: true
        )

        // 전송 전에 화면에 추가 (Android와 동일)
        chatMessages.append(msg)
        chatTableView.reloadData()
        scrollToBottom(animated: true)

        messageTextField.text = ""
        messageTextField.becomeFirstResponder()

        StompManager.shared.sendRoomMessage(msg)
    }

    // MARK: - Helpers
    private func scrollToBottom(animated: Bool) {
        guard !chatMessages.isEmpty else { return }
        let idx = IndexPath(row: chatMessages.count - 1, section: 0)
        chatTableView.scrollToRow(at: idx, at: .bottom, animated: animated)
    }

    private static func formatNow() -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
    
    private func loadChatMessages(roomId: String) {
        Task {
            do {
                let list: [ChatMessageResponse] =
                    try await AppServiceProvider.shared.getChatMessages(roomId: roomId)

                await MainActor.run {
                    self.chatMessages = list.map { m in
                        ChatMessage(
                            senderId: m.senderId,
                            message: m.message,
                            roomId: m.roomId,
                            type: "text",
                            time: m.time,
                            isMe: m.senderId == self.currentUserId
                        )
                    }

                    self.chatTableView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            } catch {
                print("❌ loadChatMessages error:", error)
            }
        }
    }
    
}

// MARK: - UITableViewDataSource / Delegate
extension ChatViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chatMessages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let msg = chatMessages[indexPath.row]
        let isMe = (msg.senderId == currentUserId)
 
        if isMe {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatRightCell", for: indexPath) as! ChatRightCell
            cell.bind(msg)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatLeftCell", for: indexPath) as! ChatLeftCell
            cell.bind(msg)
            return cell
        }
        
    }
}

// MARK: - UITextFieldDelegate (Return=Send)
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendCurrentText()
        return false
    }
}
