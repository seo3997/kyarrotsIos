import UIKit

final class ChatViewController: UIViewController {

    // MARK: - Storyboard Outlets
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBarBottom: NSLayoutConstraint!
    @IBOutlet weak var inputBarView: UIView!

    // MARK: - Inputs
    var roomId: String!
    var buyerId: String!
    var sellerId: String!
    var productId: String!
    var currentUserId: String!

    // MARK: - State
    private var otherId: String = ""
    private var chatMessages: [ChatMessage] = []
    private var topicPath: String { "/topic/\(roomId!)" }

    // ✅ “내용이 짧아도 아래 붙이기” 용 Spacer Header
    private let headerSpacer = UIView(frame: .zero)

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTapToDismissKeyboard()
        validateInputsOrPop()

        setupUI()
        setupTable()
        setupKeyboardHandling()

        resolveOtherId()
        title = "\(otherId) 님과의 대화"

        loadChatMessages(roomId: roomId)

        bindStompCallbacks()
        connectAndSubscribe()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderSpacer()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        let leaving =
            isMovingFromParent ||
            isBeingDismissed ||
            (navigationController?.isBeingDismissed ?? false)

        guard leaving else { return }

        StompManager.shared.unsubscribe(topicPath: topicPath)
        StompManager.shared.disconnect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
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

        chatTableView.separatorStyle = .none
        chatTableView.keyboardDismissMode = .interactive

        chatTableView.rowHeight = UITableView.automaticDimension
        chatTableView.estimatedRowHeight = 56

        // ✅ 원칙: inset/offset으로 아래 붙이기 X
        // ✅ 대신 header spacer로 아래 정렬
        headerSpacer.backgroundColor = .clear
        chatTableView.tableHeaderView = headerSpacer
    }

    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        chatTableView.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Header Spacer (핵심)
    /// 콘텐츠가 화면보다 짧으면 header를 늘려서 "내용이 아래로 붙는" 효과를 만듦
    private func updateHeaderSpacer() {
        // tableHeaderView 높이 계산은 contentSize가 확정된 뒤 해야 안정적
        chatTableView.layoutIfNeeded()

        let tableH = chatTableView.bounds.height

        // header를 제외한 실제 content 높이를 써야 함
        // tableHeaderView가 이미 존재하므로 그 높이를 빼고 계산
        let currentHeaderH = chatTableView.tableHeaderView?.frame.height ?? 0
        let contentHWithoutHeader = max(0, chatTableView.contentSize.height - currentHeaderH)

        // inputBar 위에 table이 붙어있다는 전제(정석 제약)
        // tableH 안에서 content가 짧으면 header로 남는 공간 채움
        let neededHeaderH = max(0, tableH - contentHWithoutHeader)

        if abs(neededHeaderH - currentHeaderH) > 0.5 {
            headerSpacer.frame = CGRect(x: 0, y: 0, width: chatTableView.bounds.width, height: neededHeaderH)
            chatTableView.tableHeaderView = headerSpacer // ✅ 이 재할당이 중요 (tableHeaderView는 frame 변경만으로 반영 안됨)
        }
    }

    // MARK: - Bottom 판단 / 스크롤
    private func isAtBottom(threshold: CGFloat = 40) -> Bool {
        chatTableView.layoutIfNeeded()
        let inset = chatTableView.adjustedContentInset
        let visibleH = chatTableView.bounds.height - inset.top - inset.bottom
        let maxOffsetY = max(-inset.top, chatTableView.contentSize.height - visibleH)
        return chatTableView.contentOffset.y >= (maxOffsetY - threshold)
    }

    private func scrollToBottom(animated: Bool) {
        chatTableView.layoutIfNeeded()
        let rows = chatMessages.count
        guard rows > 0 else { return }
        let idx = IndexPath(row: rows - 1, section: 0)
        chatTableView.scrollToRow(at: idx, at: .bottom, animated: animated)
    }

    // MARK: - Keyboard (정석)
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

        // ✅ 키보드 애니메이션 시작 전 “내가 바닥 보고 있었나”만 체크
        let follow = isAtBottom()

        let endFrameInView = view.convert(endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - endFrameInView.minY)
        let keyboardH = max(0, overlap - view.safeAreaInsets.bottom)

        inputBarBottom.constant = -keyboardH
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
            // ✅ 제약이 바뀌면 table 높이도 바뀌니 spacer도 갱신
            self.updateHeaderSpacer()
        } completion: { _ in
            if follow {
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
            stomp.subscribe(topicPath: self.topicPath)
        }

        stomp.onMessage = { [weak self] received in
            guard let self else { return }
            if received.senderId == self.currentUserId { return }

            var msg = received
            msg.isMe = false

            DispatchQueue.main.async {
                self.appendMessage(msg, forceScroll: true) // ✅ 상대 오면 무조건 아래
            }
        }

        stomp.onDisconnected = { err in
            if let err { print("❌ STOMP disconnected:", err.localizedDescription) }
        }
    }

    private func connectAndSubscribe() {
        StompManager.shared.connect(userId: currentUserId)
    }

    // MARK: - Send / Append
    @IBAction func tapSend(_ sender: Any) {
        sendCurrentText()
    }

    private func appendMessage(_ msg: ChatMessage, forceScroll: Bool) {
        chatMessages.append(msg)
        let indexPath = IndexPath(row: chatMessages.count - 1, section: 0)

        chatTableView.performBatchUpdates({
            chatTableView.insertRows(at: [indexPath], with: .none)
        }, completion: { _ in
            // ✅ contentSize 변했으니 spacer 갱신
            self.updateHeaderSpacer()

            if forceScroll {
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

        // ✅ 내 메시지도 무조건 아래
        appendMessage(msg, forceScroll: true)

        StompManager.shared.sendRoomMessage(msg)
    }

    private static func formatNow() -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }

    // MARK: - Load
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
                    self.updateHeaderSpacer()
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

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendCurrentText()
        return false
    }
}
