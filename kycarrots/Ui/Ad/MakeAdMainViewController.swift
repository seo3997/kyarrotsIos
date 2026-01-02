import UIKit

/// Kotlin: KtMakeADMainActivity 대응
final class MakeAdMainViewController: UIViewController {

    private let service: AppService
    private var draft = MakeAdDraft()

    private lazy var detailVC = MakeAdDetailViewController(service: service)
    private lazy var imageVC  = MakeAdImgRegiViewController()

    private let segmented = UISegmentedControl(items: ["상세정보", "이미지등록"])
    private let containerView = UIView()

    init(service: AppService,
         productId: String? = nil,
         adStatus: String? = nil) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
        self.draft.productId = productId
        self.draft.adStatus = adStatus
        title = (productId == nil || productId?.isEmpty == true) ? "상품 등록" : "상품 수정"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupChildren()
        bindCallbacks()
        loadIfModify()
    }

    private func setupUI() {
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(onSegmentChanged), for: .valueChanged)

        view.addSubview(segmented)
        view.addSubview(containerView)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            containerView.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "미리보기",
            style: .done,
            target: self,
            action: #selector(openPreview)
        )
    }

    private func setupChildren() {
        addChild(detailVC)
        containerView.addSubview(detailVC.view)
        detailVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            detailVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            detailVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            detailVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            detailVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        detailVC.didMove(toParent: self)

        addChild(imageVC)
        containerView.addSubview(imageVC.view)
        imageVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageVC.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageVC.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageVC.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageVC.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        imageVC.didMove(toParent: self)

        imageVC.view.isHidden = true
    }

    private func bindCallbacks() {
        detailVC.onCategoryMidChanged = { [weak self] code in
            guard let self else { return }
            Task {
                do {
                    let sub = try await self.service.getSCodeList(groupId: "R010610", mcode: code)
                    await MainActor.run {
                        self.detailVC.setSubCategoryList(sub)
                    }
                } catch {
                    await MainActor.run { self.toast("카테고리 불러오기 실패") }
                }
            }
        }
        detailVC.onAreaMidChanged = { [weak self] code in
             guard let self else { return }
             Task {
                 do {
                     // 카테고리랑 동일한 getSCodeList 시그니처 사용
                     let sub = try await self.service.getSCodeList(groupId: "R010070", mcode: code)
                     await MainActor.run {
                         self.detailVC.setSubAreaList(sub)
                     }
                 } catch {
                     await MainActor.run { self.toast("지역(소) 불러오기 실패") }
                 }
             }
         }
        imageVC.onRequestPreview = { [weak self] in
            self?.openPreview()
        }
    }

    @objc private func onSegmentChanged() {
        let isDetail = segmented.selectedSegmentIndex == 0
        detailVC.view.isHidden = !isDetail
        imageVC.view.isHidden = isDetail
    }

    private func loadIfModify() {
        let userNo = LoginInfoUtil.getUserNo()
        guard
            draft.isModify,
            let productIdStr = draft.productId,
            let productId = Int64(productIdStr),
            let userNoVal = Int64(userNo)
        else { return }

        Task {
            let detail = await service.getProductDetail(
                productId: productId,
                userNo: userNoVal
            )

            guard let detail else {
                await MainActor.run { self.toast("상품 상세 불러오기 실패") }
                return
            }

            let product = detail.product
            let images = detail.imageMetas

            var d = draft

            // =========================
            // 상품 정보 매핑 (ProductVo)
            // =========================
            d.name = product.title ?? ""
            d.detail = product.description ?? ""
            d.amount = product.price ?? ""
            d.quantity = product.quantity ?? ""
            d.unitCode = product.unitCode
            d.unitName = product.unitCodeNm
            d.desiredShippingDate = product.desiredShippingDate

            d.categoryMid = product.categoryMid
            d.categoryMidName = product.categoryMidNm
            d.categoryScls = product.categoryScls
            d.categorySclsName = product.categorySclsNm

            d.areaMid = product.areaMid
            d.areaMidName = product.areaMidNm
            d.areaScls = product.areaScls
            d.areaSclsName = product.areaSclsNm

            d.saleStatus = product.saleStatus ?? d.saleStatus
            d.systemType = product.systemType

            // =========================
            // 이미지 정보 매핑
            // =========================
            d.titleImageId = nil
            d.detailImageIds = []
            d.titleImageUrl = nil
            d.detailImageUrls = []
            d.isChangeTitleImg = false
            d.isChangeDetailImages = []

            for img in images {
                // represent == 1 → 대표 이미지
                if img.represent == 1 {
                    d.titleImageId = String(img.imageId)
                    d.titleImageUrl = img.imageUrl
                } else {
                    d.detailImageIds.append(String(img.imageId))
                    if let url = img.imageUrl {
                        d.detailImageUrls.append(url)
                    }
                    d.isChangeDetailImages.append(false)
                }
            }

            draft = d

            await MainActor.run {
                self.detailVC.applyDraft(self.draft)
                self.imageVC.applyDraft(self.draft)
            }
        }
    }

    @objc private func openPreview() {
        if let d = detailVC.collectDraft(into: draft) {
            draft = d
        } else {
            segmented.selectedSegmentIndex = 0
            onSegmentChanged()
            return
        }

        draft = imageVC.collectDraft(into: draft)

        let vc = MakeAdPreviewViewController(service: service, draft: draft)
        vc.onCompleted = { [weak self] ok in
            guard let self else { return }
            if ok { self.navigationController?.popViewController(animated: true) }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func toast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            alert.dismiss(animated: true)
        }
    }
}
