import UIKit

final class ChatViewController: UIViewController {

    // MARK: - Storyboard Outlets
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBarBottom: NSLayoutConstraint! // inputBar.bottom = SafeArea.bottom
    @IBOutlet weak var inputBarView: UIView!

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

    // ✅ inset 변화로 인한 “위로 튐” 방지용
    private var lastBottomInset: CGFloat = 0

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // ✅ 키보드가 없어도 "실제로 가려지는(overlay)" 만큼만 inset 적용 (초기 1회)
        if lastBottomInset == 0 {
            applyBottomInset(baseBottomInset(), keepVisiblePosition: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        StompManager.shared.unsubscribe(topicPath: topicPath)
        StompManager.shared.disconnect()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Tap to dismiss keyboard
    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        chatTableView.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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

    /// ✅ 더 안정적인 “바닥 근처” 판정
    private func isNearBottom(_ threshold: CGFloat = 60) -> Bool {
        let inset = chatTableView.adjustedContentInset
        let visibleHeight = chatTableView.bounds.height - inset.top - inset.bottom
        let maxOffsetY = max(-inset.top, chatTableView.contentSize.height - visibleHeight)
        return chatTableView.contentOffset.y >= (maxOffsetY - threshold)
    }

    /// ✅ chatTableView가 inputBarView에 실제로 "가려지는(overlay)" 높이만 계산
    /// - tableView.bottom이 inputBar.top에 붙어있으면 0
    /// - inputBar가 tableView 위에 떠 있으면 inputBar 높이만큼
    private func baseBottomInset() -> CGFloat {
        view.layoutIfNeeded()
        let tableBottom = chatTableView.frame.maxY
        let inputTop = inputBarView.frame.minY
        return max(0, tableBottom - inputTop)
    }

    private func applyBottomInset(_ bottomInset: CGFloat, keepVisiblePosition: Bool) {
        let old = lastBottomInset
        lastBottomInset = bottomInset

        chatTableView.contentInset.bottom = bottomInset
        chatTableView.scrollIndicatorInsets.bottom = bottomInset

        // ✅ inset이 변해도 현재 보던 내용이 “위로 튀지” 않게 offset 보정
        if keepVisiblePosition {
            let delta = bottomInset - old
            if delta != 0 {
                chatTableView.contentOffset.y += delta
            }
        }
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

        // ✅ 내가 이미 바닥 보고 있으면 키보드 올라와도 따라가기, 아니면 위치 유지
        let followBottom = isNearBottom()

        inputBarBottom.constant = -keyboardHeight
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()

            // ✅ 핵심: inputBar 높이를 무조건 더하지 말고 "실제 overlay"만 더하기
            let bottomInset = keyboardHeight + self.baseBottomInset()

            // followBottom == false면 현재 보던 위치 유지(튐 방지)
            self.applyBottomInset(bottomInset, keepVisiblePosition: !followBottom)
        } completion: { _ in
            if followBottom {
                self.scrollToBottom(animated: false)
            }
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
                // ✅ 상대 메시지 오면 무조건 맨 아래로
                self.appendMessage(msg, autoScroll: true, forceScroll: true)
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

    /// ✅ insertRows + (옵션) 강제 스크롤
    private func appendMessage(_ msg: ChatMessage, autoScroll: Bool, forceScroll: Bool = false) {
        let shouldFollow = forceScroll ? true : (autoScroll && isNearBottom())

        chatMessages.append(msg)
        let indexPath = IndexPath(row: chatMessages.count - 1, section: 0)

        chatTableView.performBatchUpdates({
            chatTableView.insertRows(at: [indexPath], with: .none)
        }, completion: { _ in
            guard shouldFollow else { return }

            // ✅ contentSize 확정 후 다음 프레임에 내려가는 게 가장 안정적
            DispatchQueue.main.async {
                self.chatTableView.layoutIfNeeded()
                self.scrollToBottom(animated: true)
            }
        })
    }

    private func sendCurrentText() {
        let text = (messageTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let now = Self.formatNow()

        let msg = ChatMessage(
            senderId: currentUserId,
            message: text,
            roomId: roomId,
            type: "text",
            time: now,
            isMe: true
        )

        messageTextField.text = ""

        // ✅ 내가 보내도 무조건 맨 아래로
        appendMessage(msg, autoScroll: true, forceScroll: true)

        StompManager.shared.sendRoomMessage(msg)
    }

    private func scrollToBottom(animated: Bool) {
        chatTableView.layoutIfNeeded()

        let contentHeight = chatTableView.contentSize.height
        let inset = chatTableView.adjustedContentInset
        let visibleHeight = chatTableView.bounds.height - inset.top - inset.bottom

        let y = max(-inset.top, contentHeight - visibleHeight)
        chatTableView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
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
                    self.chatTableView.layoutIfNeeded()

                    DispatchQueue.main.async {
                        self.scrollToBottom(animated: false)
                    }
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
