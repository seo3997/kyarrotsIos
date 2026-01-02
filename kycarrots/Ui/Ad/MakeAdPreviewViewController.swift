//
//  MakeAdPreviewViewController.swift
//  kycarrots
//

import UIKit
import Kingfisher

final class MakeAdPreviewViewController: UIViewController {

    private let service: AppService
    private var draft: MakeAdDraft
    var onCompleted: ((Bool) -> Void)?

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private let imgTitle = UIImageView()

    // ✅ 상세 이미지 3개 추가
    private var imgDetails: [UIImageView] = []

    private let lblSummary = UILabel()
    private let btnSubmit = UIButton(type: .system)

    init(service: AppService, draft: MakeAdDraft) {
        self.service = service
        self.draft = draft
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = draft.isModify ? "상품 수정 미리보기" : "상품 등록 미리보기"
        setupUI()
        bind()
    }

    func applyDraft(_ d: MakeAdDraft) {
        self.draft = d
        if isViewLoaded { bind() }
    }

    private func setupUI() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stack.axis = .vertical
        stack.spacing = 12
        scroll.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16)
        ])

        // 대표 이미지
        configImageView(imgTitle, height: 220)
        stack.addArrangedSubview(imgTitle)

        // ✅ 상세 이미지 3장 UI 추가
        let detailLabel = UILabel()
        detailLabel.text = "상세 이미지"
        detailLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        stack.addArrangedSubview(detailLabel)

        for _ in 0..<3 {
            let iv = UIImageView()
            configImageView(iv, height: 180)
            imgDetails.append(iv)
            stack.addArrangedSubview(iv)
        }

        lblSummary.numberOfLines = 0
        lblSummary.font = .systemFont(ofSize: 16)
        lblSummary.textColor = .label
        stack.addArrangedSubview(lblSummary)

        btnSubmit.setTitle(draft.isModify ? "수정 완료" : "등록", for: .normal)
        btnSubmit.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btnSubmit.heightAnchor.constraint(equalToConstant: 52).isActive = true
        btnSubmit.layer.cornerRadius = 12
        btnSubmit.layer.borderWidth = 1
        btnSubmit.layer.borderColor = UIColor.systemGray4.cgColor
        btnSubmit.addTarget(self, action: #selector(onSubmitTapped), for: .touchUpInside)
        stack.addArrangedSubview(btnSubmit)
    }

    private func configImageView(_ iv: UIImageView, height: CGFloat) {
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .systemGray5
        iv.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    private func bind() {
        btnSubmit.setTitle(draft.isModify ? "수정 완료" : "등록", for: .normal)

        // ✅ 대표 이미지 표시
        setImage(
            imageView: imgTitle,
            localData: draft.titleImageData,
            remoteUrl: draft.titleImageUrl,
            allowRemoteWhenModify: draft.isModify
        )

        // ✅ 상세 이미지 3장 표시 (Data 우선 / 수정일 때만 URL fallback)
        for i in 0..<imgDetails.count {
            let data: Data? = (draft.detailImageDatas.indices.contains(i) ? draft.detailImageDatas[i] : nil)
            let url: String? = (draft.detailImageUrls.indices.contains(i) ? draft.detailImageUrls[i] : nil)

            setImage(
                imageView: imgDetails[i],
                localData: data,
                remoteUrl: url,
                allowRemoteWhenModify: draft.isModify
            )
        }

        lblSummary.text =
"""
상품명: \(draft.name)
금액: \(draft.amount)
수량: \(draft.quantity)
단위: \(draft.unitName ?? draft.unitCode ?? "")
카테고리: \(draft.categoryMidName ?? draft.categoryMid ?? "") / \(draft.categorySclsName ?? draft.categoryScls ?? "")
지역: \(draft.areaMidName ?? draft.areaMid ?? "") / \(draft.areaSclsName ?? draft.areaScls ?? "")
희망 발송일: \(draft.desiredShippingDate ?? "")
설명:
\(draft.detail)
"""
    }

    // ✅ 공통 이미지 표시 로직
    private func setImage(
        imageView: UIImageView,
        localData: Data?,
        remoteUrl: String?,
        allowRemoteWhenModify: Bool
    ) {
        if let data = localData, !data.isEmpty, let img = UIImage(data: data) {
            imageView.kf.cancelDownloadTask()
            imageView.image = img
            return
        }

        if allowRemoteWhenModify,
           let urlStr = remoteUrl,
           !urlStr.isEmpty,
           let url = URL(string: urlStr) {
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholder"),
                options: [.transition(.fade(0.2)), .cacheOriginalImage]
            )
            return
        }

        imageView.kf.cancelDownloadTask()
        imageView.image = UIImage(named: "placeholder")
    }

    @objc private func onSubmitTapped() {
        if draft.isModify == false {
               let hasTitle = (draft.titleImageData != nil && !(draft.titleImageData?.isEmpty ?? true))
               if !hasTitle {
                   toast("대표 이미지를 선택해 주세요")
                   return
               }
        }
        print("✅ onSubmitTapped called, isModify=\(draft.isModify)")
        btnSubmit.isEnabled = false
        btnSubmit.setTitle("처리중...", for: .normal)
        Task {
            do {
                let (product, metas, images) = buildUploadPayload(from: draft)

                if draft.isModify {
                    _ = try await service.updateAdvertise(product: product, imageMetas: metas, images: images)
                } else {
                    _ = try await service.registerAdvertise(product: product, imageMetas: metas, images: images)
                }

                await MainActor.run {
                    self.btnSubmit.isEnabled = true
                    self.btnSubmit.setTitle(self.draft.isModify ? "수정 완료" : "등록", for: .normal)
                    self.onCompleted?(true)
                }
            } catch {
                print("❌ submit error:", error)
                await MainActor.run {
                    self.btnSubmit.isEnabled = true
                    self.toast("등록/수정 실패")
                    self.onCompleted?(false)
                }
            }
        }
    }

    private func buildUploadPayload(from d: MakeAdDraft) -> (ProductVo, [ProductImageVo], [Data]) {
        let userNo = LoginInfoUtil.getUserNo() // ✅ 프로젝트에 있는 util 사용
        let systemType = String(Constants.SYSTEM_TYPE)

        // ✅ Kotlin과 동일 규칙
        let saleStatus: String = {
            if systemType == "1" { return "1" }   // 판매중
            return "0"                            // 승인요청(또는 기본)
        }()

        let product = ProductVo(
            productId: d.productId,
            userNo: userNo,                       // ✅ nil 금지 (Kotlin처럼 세팅)
            title: d.name,
            description: d.detail,
            price: d.amount,
            categoryGroup: "R010610",             // ✅ Kotlin 고정
            categoryMid: d.categoryMid,
            categoryScls: d.categoryScls,
            saleStatus: saleStatus,               // ✅ Kotlin 규칙 강제
            areaGroup: "R010070",                 // ✅ Kotlin 고정
            areaMid: d.areaMid,
            areaScls: d.areaScls,
            quantity: d.quantity,
            unitGroup: "R010620",                 // ✅ Kotlin 고정
            unitCode: d.unitCode,
            desiredShippingDate: d.desiredShippingDate,
            registerNo: userNo,                   // ✅ Kotlin: userNo
            registDt: "",
            updusrNo: userNo,                     // ✅ Kotlin: userNo
            updtDt: "",
            imageUrl: nil,
            categoryMidNm: nil,
            categorySclsNm: nil,
            areaMidNm: nil,
            areaSclsNm: nil,
            unitCodeNm: nil,
            saleStatusNm: nil,
            userId: nil,
            wholesalerNo: nil,
            wholesalerId: nil,
            fav: nil,
            systemType: systemType,               // ✅ Kotlin과 동일 (무조건 "1"/"2")
            rejectReason: nil
        )

        var metas: [ProductImageVo] = []
        var images: [Data] = []

        func appendImage(data: Data, imageId: Int64?, represent: Int) {
            images.append(data)
            metas.append(
                ProductImageVo(
                    imageId: imageId ?? 0,
                    productId: 0,
                    imageCd: represent == 1 ? "1" : "0",
                    imageUrl: nil,
                    imageName: nil,
                    represent: represent,
                    imageSize: Int64(data.count),
                    imageText: nil,
                    imageType: "image/jpeg",
                    registerNo: 0,
                    registDt: nil,
                    updusrNo: 0,
                    updtDt: nil
                )
            )
        }

        if d.isModify {
            if d.isChangeTitleImg, let data = d.titleImageData, !data.isEmpty {
                appendImage(data: data, imageId: stringToInt64(d.titleImageId), represent: 1)
            }
            for idx in 0..<d.detailImageDatas.count {
                let changed = d.isChangeDetailImages.indices.contains(idx) ? d.isChangeDetailImages[idx] : false
                guard changed else { continue }
                let data = d.detailImageDatas[idx]
                guard !data.isEmpty else { continue }

                let imageId = d.detailImageIds.indices.contains(idx) ? stringToInt64(d.detailImageIds[idx]) : nil
                appendImage(data: data, imageId: imageId, represent: 0)
            }
        } else {
            // 등록: Data 있는 것 전부
            if let data = d.titleImageData, !data.isEmpty {
                appendImage(data: data, imageId: nil, represent: 1)
            }
            for data in d.detailImageDatas where !data.isEmpty {
                appendImage(data: data, imageId: nil, represent: 0)
            }
        }

        return (product, metas, images)
    }

    private func toast(_ msg: String) {
        let alert = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { alert.dismiss(animated: true) }
    }
}
