import UIKit
import Kingfisher
import Foundation

final class ProductDetailViewController: UIViewController {

    // MARK: - IBOutlets (Storyboard)
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var expandedTitleLabel: UILabel!   // 헤더 위 큰 타이틀
    @IBOutlet weak var section1CardView: UIView!
    @IBOutlet weak var section2CardView: UIView!
    @IBOutlet weak var section1DescLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var shipDateLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    // 서브 이미지 3개 + 컨테이너 (없으면 숨김)
    @IBOutlet weak var subImageContainerView: UIView!
    @IBOutlet weak var subImage1: UIImageView!
    @IBOutlet weak var subImage2: UIImageView!
    @IBOutlet weak var subImage3: UIImageView!

    // 상태 변경용: 변경 가능이면 field(피커), read-only면 label
    @IBOutlet weak var statusField: UITextField!
    @IBOutlet weak var statusReadonlyLabel: UILabel!

    // 반려 사유 카드
    @IBOutlet weak var rejectReasonCardView: UIView!
    @IBOutlet weak var rejectReasonLabel: UILabel!

    // 버튼들
    @IBOutlet weak var editButton: UIButton!      // 판매자만 보이게
    //@IBOutlet weak var chatButton: UIButton!      // FAB 역할

    // 로딩
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    // MARK: - Inputs (Android Intent 대응)
    var productId: Int64 = 0
    var productUserId: String = "0"
    var productTitle: String = ""
    var pushType: String?
    var pushMsg: String?
    
    // MARK: - Parallax/Collapsing
    private let headerBaseHeight: CGFloat = 260
    private let navBarThreshold: CGFloat = 120
    private var navBarOverlay: UIView?
    private var navProgress: CGFloat = 0

    override var preferredStatusBarStyle: UIStatusBarStyle {
        navProgress < 0.5 ? .lightContent : .default
    }

    // MARK: - State (Android 변수 대응)
    private var wholesalerId: String = ""
    private var memberCode: String = ""     // ROLE_PUB / ROLE_SELL / ROLE_PROJ
    private var systemType: Int = 1         // Constants.SYSTEM_TYPE
    private var isFav: Bool = false

    private var currentStatus: String?
    private var statusChanged: Bool = false
    private var newStatus: String?

    private var statusList: [TxtListDataInfo] = []
    private var filteredList: [TxtListDataInfo] = []

    private var selectedBuyerForCompletion: ChatBuyerDto? = nil

    // 이미지 URL 저장
    private var mainImageUrlString: String?
    private var subImageUrls: [String] = []

    // Picker
    private let statusPicker = UIPickerView()
    
    func styleRejectReasonCard(_ view: UIView) {
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = false

        // 배경색 (Android: cardBackgroundColor="#FFF7F7")
        view.backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.97, alpha: 1.0)

        // strokeWidth + strokeColor 대응
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemRed.cgColor

        // elevation 대응 (그림자)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 2
    }

    
    private let chatButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemGreen   // 앱 대표색
        button.setImage(UIImage(systemName: "bubble.left.and.bubble.right.fill"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowRadius = 4
        return button
    }()

    private func setupChatButton() {
        view.addSubview(chatButton) // ⚠️ headerContainerView가 아니라 view에 추가

        NSLayoutConstraint.activate([
            chatButton.widthAnchor.constraint(equalToConstant: 56),
            chatButton.heightAnchor.constraint(equalToConstant: 56),

            // 오른쪽 정렬 (헤더 기준)
            chatButton.trailingAnchor.constraint(
                equalTo: headerContainerView.trailingAnchor,
                constant: -16
            ),

            // ✅ 헤더 하단에 걸치기 (중요)
            chatButton.topAnchor.constraint(
                equalTo: headerContainerView.bottomAnchor,
                constant: -28   // 버튼 높이의 절반
            )
        ])

        chatButton.addTarget(self, action: #selector(onTapChat), for: .touchUpInside)
    }

    @objc private func didTapChatButton() {
        // TODO: Android handleFabClickForSystemType1 / 2 대응
        print("💬 Chat button tapped")

        // 예시
        /*
        let vc = ChatViewController()
        vc.roomId = ...
        navigationController?.pushViewController(vc, animated: true)
        */
    }
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupChatButton()
        styleRejectReasonCard(rejectReasonCardView)
        // ✅ 프로젝트 유틸/상수로 값 주입(여기만 너 프로젝트에 맞게)
        systemType = Constants.SYSTEM_TYPE
        memberCode = LoginInfoUtil.getMemberCode()
        navigationItem.title = productTitle.isEmpty ? "상품 상세" : productTitle
        expandedTitleLabel.text = navigationItem.title
        
        section1DescLabel.numberOfLines = 0
        section1DescLabel.lineBreakMode = .byWordWrapping

        rejectReasonLabel.numberOfLines = 0
        rejectReasonLabel.lineBreakMode = .byWordWrapping

        setupScrollView()
        setupHeaderView()
        //setupNavBarAppearance()
        setupNavBarOverlayIfNeeded()
        setupActions()
        setupStatusPicker()

        bindPlaceholders()

        // ✅ Android loadProductDetail()
        loadProductDetail()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Android onResume처럼 재조회
        if productId > 0 { loadProductDetail() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        section1CardView.applyCardStyle()
        section2CardView.applyCardStyle()
        navBarOverlay?.frame = navigationController?.navigationBar.bounds ?? .zero
    }

    // MARK: - Setup
    private func setupScrollView() {
        scrollView.delegate = self
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
    }

    private func setupHeaderView() {
        headerHeightConstraint.constant = headerBaseHeight
        productImageView.contentMode = .scaleAspectFill
        productImageView.clipsToBounds = true

        expandedTitleLabel.textColor = .red
        expandedTitleLabel.numberOfLines = 2
        expandedTitleLabel.alpha = 1

        productImageView.isUserInteractionEnabled = true
        productImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapMainImage)))

        let subs = [subImage1, subImage2, subImage3]
        for (i, v) in subs.enumerated() {
            v?.isUserInteractionEnabled = true
            v?.tag = i
            v?.contentMode = .scaleAspectFill
            v?.clipsToBounds = true
            v?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapSubImage(_:))))
        }
    }

    private func setupNavBarAppearance() {
        // Expanded(상단): 투명 + label(다크모드 자동)
        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        edge.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        // Collapsed: 기본 + 흰색 (overlay 위에 선명)
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        standard.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        navigationController?.navigationBar.scrollEdgeAppearance = edge
        navigationController?.navigationBar.standardAppearance = standard
        navigationController?.navigationBar.compactAppearance = standard
        navigationController?.navigationBar.tintColor = .white

        //navigationItem.title = "" // 스크롤에 따라 표시
    }

    private func setupNavBarOverlayIfNeeded() {
        guard let navBar = navigationController?.navigationBar else { return }
        if navBarOverlay == nil {
            let overlay = UIView(frame: navBar.bounds)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.backgroundColor = UIColor.systemGreen
            overlay.alpha = 0
            navBar.insertSubview(overlay, at: 0)
            navBarOverlay = overlay
        }
    }

    private func setupActions() {
        chatButton.addTarget(self, action: #selector(onTapChat), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(onTapEdit), for: .touchUpInside)

        // 찜(구매자만 보여야 함) - 네비바 우측 버튼
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(onTapFavorite)
        )
        navigationItem.rightBarButtonItem?.isHidden = true
    }

    private func setupStatusPicker() {
        statusPicker.dataSource = self
        statusPicker.delegate = self

        statusField.inputView = statusPicker
        statusField.tintColor = .clear

        // ✅ 터치/편집 가능하게
        statusField.isUserInteractionEnabled = true
        statusField.isEnabled = true
        applyDropdownStyle(to: statusField)
        // ✅ 탭하면 picker 뜨게 (편집 시작을 강제로)
        let tap = UITapGestureRecognizer(target: self, action: #selector(openStatusPicker))
        statusField.addGestureRecognizer(tap)

        let bar = UIToolbar()
        bar.sizeToFit()
        bar.items = [
            UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(onCancelStatusPick)),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "확인", style: .done, target: self, action: #selector(onConfirmStatusPick))
        ]
        statusField.inputAccessoryView = bar
    }
    private func applyDropdownStyle(to textField: UITextField) {
        textField.backgroundColor = .systemBackground
        textField.layer.cornerRadius = 10
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor

        // 왼쪽 패딩
        let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        textField.leftView = leftPad
        textField.leftViewMode = .always

        // 오른쪽 ▼ 아이콘
        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .systemGray2
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 0, y: 0, width: 22, height: 22)

        let rightWrap = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 22))
        chevron.center = CGPoint(x: rightWrap.bounds.midX, y: rightWrap.bounds.midY)
        rightWrap.addSubview(chevron)

        textField.rightView = rightWrap
        textField.rightViewMode = .always

        // 드롭다운 느낌(편집 불가처럼 보이게)
        textField.clearButtonMode = .never
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
    }
    @objc private func openStatusPicker() {
        statusField.becomeFirstResponder()
    }
    private func bindPlaceholders() {
        priceLabel.text = "-"
        areaLabel.text = "-"
        shipDateLabel.text = "-"
        quantityLabel.text = "-"
        categoryLabel.text = "-"
        //expandedTitleLabel.text = ""
        productImageView.image = UIImage(named: "placeholder")
        subImageContainerView.isHidden = true
        rejectReasonCardView.isHidden = true
        statusReadonlyLabel.isHidden = true
        statusField.isHidden = true
        loadingView.isHidden = true
    }

    // MARK: - Loading
    private func showLoading(_ show: Bool) {
        if show {
            loadingView.isHidden = false
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
            loadingView.isHidden = true
        }
    }
    
    // MARK: - Data Load (Android loadProductDetail)
    private func loadProductDetail() {
        guard productId > 0 else { return }
        showLoading(true)

        Task {
            do {
                let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0

                if let detail = try await AppServiceProvider.shared
                    .getProductDetail(productId: productId, userNo: userNo) {

                    await MainActor.run {
                        self.showProductDetail(detail)
                    }
                }

                await MainActor.run {
                    self.showLoading(false)
                }

            } catch {
                print("❌ loadProductDetail error:", error)

                await MainActor.run {
                    self.showLoading(false)
                }
            }
        }
    }

    // MARK: - Render (Android showProductDetail)
    private func showProductDetail(_ detail: ProductDetailResponse) {
        let title = detail.product.title ?? "상품 상세"

        expandedTitleLabel.text = title
      
        // collapsing toolbar title (스크롤 후에만 표시)
        navigationItem.title = title
        let shipDate = detail.product.desiredShippingDate ?? "-"   // 예: "2025-11-01"
            shipDateLabel.text = "희망출하일: \(shipDate)"
        // 수량
        let qtyText = formatCommaNoDecimal(detail.product.quantity)
        let unit = detail.product.unitCodeNm ?? ""
        quantityLabel.text = "수량: \(qtyText)\(unit)"

        // ✅ 카테고리 (서버 필드명에 맞게 바꿔)
        let cm = detail.product.categoryMidNm ?? ""
        let cs = detail.product.categorySclsNm ?? ""
        let cat = [cm, cs].filter { !$0.isEmpty }.joined(separator: " > ")
        categoryLabel.text = "카테고리: \(cat.isEmpty ? "-" : cat)"
        wholesalerId = detail.product.wholesalerId ?? ""
        isFav = (detail.product.fav == "1")

        section1DescLabel.text = detail.product.description ?? ""
        let priceText = formatCommaNoDecimal(detail.product.price)
        priceLabel.text = "가격:\(priceText)원"
        
        let areaMid = detail.product.areaMidNm ?? ""
        let areaScls = detail.product.areaSclsNm ?? ""
        areaLabel.text = "지역: \(areaMid) \(areaScls)"

   
        // 대표/서브 이미지
        applyImageMetas(detail.imageMetas)

        // 반려 사유
        renderRejectReason(currentStatus: detail.product.saleStatus, rejectReason: detail.product.rejectReason)

        // 찜 버튼(구매자만)
        applyFavoriteVisibilityAndIcon()

        // 수정 버튼(판매자만)
        editButton.isHidden = (memberCode != Constants.ROLE_SELL)

        // 상태 옵션 로딩
        currentStatus = detail.product.saleStatus
        loadProductStatusOptions(systemType: systemType, currentStatus: currentStatus)
    }
    // MARK: - Images (Glide -> Kingfisher)
    private func applyImageMetas(_ metas: [ProductImageVo]) {
        let main = metas.first(where: { $0.represent == 1 })?.imageUrl
        let subs = metas.filter { $0.represent == 0 }.compactMap { $0.imageUrl }

        mainImageUrlString = main
        subImageUrls = subs

        bindImages(mainUrl: main, subUrls: subs)
    }

    private func bindImages(mainUrl: String?, subUrls: [String]) {
        // ✅ Main
        if let s = mainUrl, let url = URL(string: s) {
            productImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholder"),
                options: [.transition(.fade(0.2)), .cacheOriginalImage]
            )
        } else {
            productImageView.image = UIImage(named: "placeholder")
        }

        // ✅ Subs
        let views: [UIImageView?] = [subImage1, subImage2, subImage3]
        let urls = Array(subUrls.prefix(3))
        subImageContainerView.isHidden = urls.isEmpty

        for (i, iv) in views.enumerated() {
            guard let iv else { continue }

            if i < urls.count, let url = URL(string: urls[i]) {
                iv.isHidden = false
                iv.kf.setImage(
                    with: url,
                    placeholder: UIImage(named: "placeholder"),
                    options: [.transition(.fade(0.2)), .cacheOriginalImage]
                )
            } else {
                iv.isHidden = true
                iv.image = nil
            }
        }
    }

    @objc private func onTapMainImage() {
        guard let s = mainImageUrlString else { return }
        openImageViewer(urlString: s)
    }

    @objc private func onTapSubImage(_ gr: UITapGestureRecognizer) {
        guard let v = gr.view else { return }
        let idx = v.tag
        guard idx >= 0, idx < subImageUrls.count else { return }
        openImageViewer(urlString: subImageUrls[idx])
    }

    private func openImageViewer(urlString: String) {
        // TODO: 너 iOS ImageViewerVC로 push/present
        // 예: let vc = ImageViewerViewController(urlString: urlString)
        // navigationController?.pushViewController(vc, animated: true)
        print("openImageViewer:", urlString)
    }

    // MARK: - Reject Reason Card
    private func renderRejectReason(currentStatus: String?, rejectReason: String?) {
        if currentStatus == "98", let r = rejectReason, !r.isEmpty {
            rejectReasonCardView.isHidden = false
            rejectReasonLabel.text = r
        } else {
            rejectReasonCardView.isHidden = true
            rejectReasonLabel.text = ""
        }
    }

    // MARK: - Favorite (Android toggleFavorite)
    private func applyFavoriteVisibilityAndIcon() {
        let isBuyer = (memberCode == Constants.ROLE_PUB)
        navigationItem.rightBarButtonItem?.isHidden = !isBuyer
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: isFav ? "heart.fill" : "heart")
    }

    @objc private func onTapFavorite() {
        guard memberCode == Constants.ROLE_PUB else {
            showAlert(title: "안내", message: "구매자만 찜하기가 가능합니다")
            return
        }

        Task {
            do {
                showLoading(true)
                defer { showLoading(false) }
                let userNo = Int64(LoginInfoUtil.getUserNo()) ?? 0

                let req = InterestRequest(
                    userNo: userNo,
                    productId: productId
                )
                let ok = try await AppServiceProvider.shared.toggleInterest(req)

                await MainActor.run {
                    if ok {
                        self.isFav.toggle()
                        self.applyFavoriteVisibilityAndIcon()
                    } else {
                        self.showAlert(title: "실패", message: "서버 오류로 실패했습니다")
                    }
                }
            } catch {
                await MainActor.run { self.showAlert(title: "오류", message: error.localizedDescription) }
            }
        }
    }

    // MARK: - Status Options (Android loadProductStatusOptions + handleStatusChange)
    private func loadProductStatusOptions(systemType: Int, currentStatus: String?) {
        let isReadonly: Bool = {
            if memberCode == Constants.ROLE_PUB { return true }
            if systemType == 2 && memberCode == Constants.ROLE_SELL && currentStatus == "0" { return true }
            if systemType == 2 && memberCode == Constants.ROLE_PROJ && currentStatus == "98" { return true }
            return false
        }()

        if isReadonly {
            statusField.isHidden = true
            statusReadonlyLabel.isHidden = false

            Task {
                do {
                    let apiList = try await AppServiceProvider.shared.getCodeList(groupId: "R010630")
                    let label = apiList.first(where: { $0.strIdx == currentStatus })?.strMsg ?? "알 수 없음"
                    await MainActor.run { self.statusReadonlyLabel.text = "현재 상태: \(label)" }
                } catch {
                    await MainActor.run { self.statusReadonlyLabel.text = "현재 상태: 알 수 없음" }
                }
            }
            return
        }

        statusField.isHidden = false
        statusReadonlyLabel.isHidden = true

        Task {
            do {
                let list = try await AppServiceProvider.shared.getCodeList(groupId: "R010630")
                statusList = list

                filteredList = list.filter { item in
                    let idx = item.strIdx
                    switch (systemType, memberCode) {
                    case (1, Constants.ROLE_SELL):
                        return ["1","10","99"].contains(idx) || idx == currentStatus
                    case (2, Constants.ROLE_PROJ):
                        return ["0","1","10","98","99"].contains(idx) || idx == currentStatus
                    case (2, Constants.ROLE_SELL):
                        return ["0","98"].contains(idx) // 반려 상태에서 승인요청만
                    default:
                        return false
                    }
                }

                // distinctBy strIdx
                let dict = Dictionary(grouping: filteredList, by: { $0.strIdx ?? "" })
                filteredList = dict.values.compactMap { $0.first }

                await MainActor.run {
                    self.statusPicker.reloadAllComponents()
                    if let cur = currentStatus,
                       let idx = self.filteredList.firstIndex(where: { $0.strIdx == cur }) {
                        self.statusPicker.selectRow(idx, inComponent: 0, animated: false)
                        self.statusField.text = self.filteredList[idx].strMsg
                    } else {
                        self.statusField.text = self.filteredList.first?.strMsg
                    }
                }

            } catch {
                print("❌ status list load error:", error)
            }
        }
    }

    @objc private func onCancelStatusPick() {
        restoreStatusSelection()
    }

    @objc private func onConfirmStatusPick() {
        let row = statusPicker.selectedRow(inComponent: 0)
        guard row >= 0, row < filteredList.count else {
            statusField.resignFirstResponder()
            return
        }

        let selected = filteredList[row]
        let label = selected.strMsg ?? ""
        let code = selected.strIdx ?? ""

        if code == currentStatus {
            statusField.resignFirstResponder()
            return
        }

        statusField.text = label
        statusField.resignFirstResponder()

        handleStatusChange(label: label, code: code)
    }

    private func restoreStatusSelection() {
        guard let cur = currentStatus,
              let idx = filteredList.firstIndex(where: { $0.strIdx == cur }) else {
            statusField.resignFirstResponder()
            return
        }
        statusPicker.selectRow(idx, inComponent: 0, animated: false)
        statusField.text = filteredList[idx].strMsg
        statusField.resignFirstResponder()
    }

    private func handleStatusChange(label: String, code: String) {
        let canChange: Bool = {
            switch (systemType, memberCode) {
            case (1, Constants.ROLE_SELL): return ["1","10","99"].contains(code)
            case (2, Constants.ROLE_PROJ): return ["1","10","98","99"].contains(code)
            case (2, Constants.ROLE_SELL): return (currentStatus == "98" && code == "0")
            default: return false
            }
        }()

        guard canChange else {
            showAlert(title: "안내", message: "이 상태에서는 변경할 수 없습니다.")
            restoreStatusSelection()
            return
        }

        if code == "99" {
            maybePickBuyerThenConfirm(label: label, code: code)
            return
        }

        if currentStatus == "0", code == "98" {
            askRejectReason { reason in
                self.showStatusChangeConfirm(label: label, code: code, rejectReason: reason)
            }
        } else {
            showStatusChangeConfirm(label: label, code: code, rejectReason: nil)
        }
    }

    private func maybePickBuyerThenConfirm(label: String, code: String) {
        Task {
            do {
                showLoading(true)
                defer { showLoading(false) }

                let sellerId = resolveSellerId()
                let buyers = try await AppServiceProvider.shared.getChatBuyers(productId: productId, sellerId: sellerId)

                await MainActor.run {
                    if buyers.isEmpty {
                        self.selectedBuyerForCompletion = nil
                        self.showStatusChangeConfirm(label: label, code: code, rejectReason: nil)
                    } else {
                        self.showBuyerPickSheet(buyers: buyers) { picked in
                            self.selectedBuyerForCompletion = picked
                            self.showStatusChangeConfirm(label: label, code: code, rejectReason: nil)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.selectedBuyerForCompletion = nil
                    self.showStatusChangeConfirm(label: label, code: code, rejectReason: nil)
                }
            }
        }
    }

    private func showBuyerPickSheet(buyers: [ChatBuyerDto], onPick: @escaping (ChatBuyerDto?) -> Void) {
        let alert = UIAlertController(title: "판매완료 처리 — 구매자 선택", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "선택 안함", style: .default) { _ in onPick(nil) })
        buyers.forEach { b in
            alert.addAction(UIAlertAction(title: "\(b.buyerId)/\(b.buyerNm)", style: .default) { _ in onPick(b) })
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            self.restoreStatusSelection()
        })
        present(alert, animated: true)
    }

    private func askRejectReason(onDone: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "반려 사유 입력", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "반려 사유를 입력하세요" }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            self.restoreStatusSelection()
        })
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            let reason = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if reason.isEmpty {
                self.showAlert(title: "안내", message: "반려 사유를 입력해주세요.")
                self.restoreStatusSelection()
            } else {
                onDone(reason)
            }
        })
        present(alert, animated: true)
    }

    private func showStatusChangeConfirm(label: String, code: String, rejectReason: String?) {
        let buyer = (code == "99") ? selectedBuyerForCompletion : nil
        let buyerLine = buyer.map { "\n\n선택한 구매자: \($0.buyerNm)" } ?? ""

        let message: String
        if let rejectReason, !rejectReason.isEmpty {
            message = "상태를 \"\(label)\"(으)로 변경하고 아래 사유를 저장하시겠습니까?\n\n사유: \(rejectReason)\(buyerLine)"
        } else {
            message = "상태를 \"\(label)\"(으)로 변경하시겠습니까?\(buyerLine)"
        }

        let alert = UIAlertController(title: "상태 변경 확인", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
            self.restoreStatusSelection()
        })
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            Task {
                let ok = await self.createPurchaseIfNeeded(code: code, buyer: buyer)
                if ok {
                    await self.updateProductStatus(code: code, rejectReason: rejectReason)
                }
            }
        })
        present(alert, animated: true)
    }

    private func createPurchaseIfNeeded(code: String, buyer: ChatBuyerDto?) async -> Bool {
        guard code == "99", let buyer else { return true }
        do {
            showLoading(true)
            defer { showLoading(false) }
            let req = PurchaseHistoryRequest(
                productId: productId,
                buyerNo: buyer.buyerNo,
                roomId: buyer.roomId,
                sellerNo: buyer.sellerNo
            )
            _ = try await AppServiceProvider.shared.createPurchase(req)
            
            return true
        } catch {
            await MainActor.run { self.showAlert(title: "오류", message: error.localizedDescription) }
            return false
        }
    }

    private func updateProductStatus(code: String, rejectReason: String?) async {
        do {
            showLoading(true)
            defer { showLoading(false) }

            let token = TokenUtil.getToken()
            let item = ProductItem(
                productId: String(productId),
                saleStatus: code,
                updusrNo: 0,
                rejectReason: rejectReason,
                systemType: String(systemType)
            )

            let success = try await AppServiceProvider.shared.updateProductStatus(token: token, product: item)
            await MainActor.run {
                if success {
                    self.newStatus = code
                    self.statusChanged = true
                    self.currentStatus = code
                    self.renderRejectReason(currentStatus: code, rejectReason: rejectReason)
                    self.loadProductStatusOptions(systemType: self.systemType, currentStatus: self.currentStatus)
                    self.showAlert(title: "완료", message: "상태가 변경되었습니다.")
                } else {
                    self.showAlert(title: "실패", message: "상태 변경 실패")
                    self.restoreStatusSelection()
                }
            }
        } catch {
            await MainActor.run {
                self.showAlert(title: "오류", message: error.localizedDescription)
                self.restoreStatusSelection()
            }
        }
    }

    // MARK: - Chat (Android handleFabClickForSystemType1/2)
    @objc private func onTapChat() {
        switch systemType {
        case 1: handleChatSystemType1()
        case 2: handleChatSystemType2()
        default: showAlert(title: "안내", message: "지원하지 않는 시스템 유형입니다.")
        }
    }

    private func handleChatSystemType1() {
        let myId = LoginInfoUtil.getUserId()
        let isBuyer = (memberCode == Constants.ROLE_PUB)

        let buyerId = isBuyer ? myId : ""
        let sellerId = resolveSellerId()
        let pid = String(productId)

        if isBuyer {
            createOrGetRoom(productId: pid, buyerId: buyerId, sellerId: sellerId)
        } else {
            fetchRoomListForSeller(productId: pid, sellerId: sellerId)
        }
    }

    private func handleChatSystemType2() {
        let myId = LoginInfoUtil.getUserId()
        let pid = String(productId)

        switch memberCode {
        case Constants.ROLE_PUB:
            createOrGetRoom(productId: pid, buyerId: myId, sellerId: resolveSellerId())

        case Constants.ROLE_SELL:
            fetchRoomListForSeller(productId: pid, sellerId: myId)

        case Constants.ROLE_PROJ:
            let alert = UIAlertController(title: "채팅 대상 선택", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "판매자에게 채팅", style: .default) { _ in
                self.createOrGetRoom(productId: pid, buyerId: myId, sellerId: self.productUserId)
            })
            alert.addAction(UIAlertAction(title: "구매자에게 채팅", style: .default) { _ in
                self.fetchRoomListForSeller(productId: pid, sellerId: myId)
            })
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alert, animated: true)

        default:
            showAlert(title: "안내", message: "알 수 없는 사용자 역할입니다.")
        }
    }

    private func createOrGetRoom(productId: String, buyerId: String, sellerId: String) {
        Task {
            do {
                let room = try await AppServiceProvider.shared.createOrGetChatRoom(productId: productId, buyerId: buyerId, sellerId: sellerId)
                await MainActor.run {
                    guard let room else {
                        self.showAlert(title: "실패", message: "채팅방 생성 실패")
                        return
                    }
                    self.openChat(roomId: room.roomId, buyerId: room.buyerId, sellerId: room.sellerId, productId: String(room.productId))
                }
            } catch {
                await MainActor.run { self.showAlert(title: "오류", message: "네트워크 오류") }
            }
        }
    }

    private func fetchRoomListForSeller(productId: String, sellerId: String) {
        Task {
            do {
                let rooms = try await AppServiceProvider.shared.getUserChatRooms(productId: productId, userId: sellerId)
                await MainActor.run {
                    if rooms.isEmpty {
                        self.showAlert(title: "안내", message: "이 상품에 대한 채팅 요청이 없습니다")
                    } else if rooms.count == 1, let r = rooms.first {
                        self.openChat(roomId: r.roomId, buyerId: r.buyerId, sellerId: r.sellerId, productId: String(r.productId))
                    } else {
                        self.showBuyerSelectionDialog(rooms: rooms)
                    }
                }
            } catch {
                await MainActor.run { self.showAlert(title: "오류", message: "네트워크 오류") }
            }
        }
    }

    private func showBuyerSelectionDialog(rooms: [ChatRoomResponse]) {
        let alert = UIAlertController(title: "구매자를 선택하세요", message: nil, preferredStyle: .actionSheet)
        for (i, r) in rooms.enumerated() {
            alert.addAction(UIAlertAction(title: "구매자 \(i+1): \(r.buyerId)", style: .default) { _ in
                self.openChat(roomId: r.roomId, buyerId: r.buyerId, sellerId: r.sellerId, productId: String(r.productId))
            })
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

    private func openChat(roomId: String, buyerId: String, sellerId: String, productId: String) {
        // TODO: 너 프로젝트의 ChatViewController로 push
        // let vc = ChatViewController()
        // vc.roomId = roomId ...
        // navigationController?.pushViewController(vc, animated: true)
        print("openChat:", roomId, buyerId, sellerId, productId)
        
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "ChatVC") as? ChatViewController else {
            self.showAlert(title: "오류", message: "ChatVC 화면을 찾을 수 없습니다(Storyboard ID 확인).")
            return
        }

        // Android Intent extras 대응
        vc.roomId = roomId
        vc.buyerId = buyerId
        vc.sellerId = sellerId
        vc.productId = productId
        vc.currentUserId = LoginInfoUtil.getUserId()   // ✅ sUID 넣기 (너 프로젝트 함수에 맞게)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func resolveSellerId() -> String {
        switch systemType {
        case 1: return productUserId
        case 2: return wholesalerId
        default: return productUserId
        }
    }

    // MARK: - Edit
    @objc private func onTapEdit() {
        // TODO: iOS 상품 수정 화면으로 push
        print("edit product:", productId)
        let vc = MakeAdMainViewController(
             service: AppServiceProvider.shared,
             productId: String(productId)
        )
        navigationController?.pushViewController(vc, animated: true)

    }

    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "확인", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Scroll / Parallax + Collapsing
extension ProductDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        /*
        let offsetY = scrollView.contentOffset.y

        if offsetY < 0 {
            headerHeightConstraint.constant = headerBaseHeight - offsetY
            productImageView.transform = .identity
        } else {
            headerHeightConstraint.constant = max(headerBaseHeight - offsetY, 0)
            let parallaxRatio: CGFloat = 0.5
            productImageView.transform = CGAffineTransform(translationX: 0, y: -offsetY * parallaxRatio)
        }
         */
        /*
        let p = min(max((offsetY - navBarThreshold) / 80.0, 0), 1)
        navProgress = p
        navBarOverlay?.alpha = p

        expandedTitleLabel.alpha = max(0, 1 - p * 1.2)

        if p > 0.6 {
            navigationItem.title = expandedTitleLabel.text ?? "상품 상세"
        } else {
            //navigationItem.title = ""
            navigationItem.title = expandedTitleLabel.text ?? "상품 상세"
        }
        
        setNeedsStatusBarAppearanceUpdate()
         */
    }
}

// MARK: - Picker
extension ProductDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        filteredList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        filteredList[row].strMsg
    }
}

