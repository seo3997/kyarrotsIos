//
//  MakeAdPreviewViewController.swift
//  kycarrots
//

import UIKit
import Kingfisher
import Foundation

final class MakeAdPreviewViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var section1CardView: UIView!
    @IBOutlet weak var section2CardView: UIView!
    @IBOutlet weak var section1DescLabel: UILabel!

    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var shipDateLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!

    @IBOutlet weak var imgTitle: UIImageView!
    @IBOutlet weak var imgDetail1: UIImageView!
    @IBOutlet weak var imgDetail2: UIImageView!
    @IBOutlet weak var imgDetail3: UIImageView!
    @IBOutlet weak var lblSummary: UILabel!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var lblDetailTitle: UILabel!
    private var service: AppService!
    private var draft: MakeAdDraft!
    var onCompleted: ((Bool) -> Void)?

    private var imgDetails: [UIImageView] = []

    static func instantiate(
        service: AppService,
        draft: MakeAdDraft
    ) -> MakeAdPreviewViewController {

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(
            withIdentifier: "MakeAdPVC"
        ) as! MakeAdPreviewViewController

        vc.service = service
        vc.draft = draft
        return vc
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        section1CardView.applyCardStyle()
        section2CardView.applyCardStyle()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imgDetails = [imgDetail1, imgDetail2, imgDetail3]   // ✅ 필수

        btnSubmit.addTarget(self, action: #selector(onSubmitTapped), for: .touchUpInside) // ✅ 스토리보드면 액션 연결 or 이걸로

        view.backgroundColor = .systemBackground
        title = draft.isModify ? "상품 수정 미리보기" : "상품 등록 미리보기"
        bind()
    }
    func applyDraft(_ d: MakeAdDraft) {
        self.draft = d
        if isViewLoaded { bind() }
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
        
        // ✅ 빈 상세이미지 슬롯은 미리보기에서 숨김
        var anyDetail = false
        for i in 0..<imgDetails.count {
            let has = hasDetailImage(at: i)
            imgDetails[i].isHidden = !has
            if has { anyDetail = true }
        }
        lblDetailTitle.isHidden = !anyDetail
        
        
        lblSummary.text =
"""
상품명: \(draft.name)
설명:
\(draft.detail)
"""
        
        //가격
        let priceText = formatCommaNoDecimal(draft.amount)
        priceLabel.text = "가격:\(priceText)원"
        
        //희망출하일
        let shipDate = draft.desiredShippingDate ?? "-"   // 예: "2025-11-01"
        shipDateLabel.text = "희망출하일: \(shipDate)"
        
        // 수량
        let qtyText = formatCommaNoDecimal(draft.quantity)
        let unit = draft.unitName ?? draft.unitCode ?? ""
        quantityLabel.text = "수량: \(qtyText)\(unit)"
        
        // 카테고리 (서버 필드명에 맞게 바꿔)
        let cm = draft.categoryMidName ?? draft.categoryMid ?? ""
        let cs = draft.categorySclsName ?? draft.categoryScls ?? ""
        let cat = [cm, cs].filter { !$0.isEmpty }.joined(separator: " > ")
        categoryLabel.text = "카테고리: \(cat.isEmpty ? "-" : cat)"
        
        
        let areaMid = draft.areaMidName ?? draft.areaMid ?? ""
        let areaScls = draft.areaSclsName ?? draft.areaScls ?? ""
        areaLabel.text = "지역: \(areaMid) \(areaScls)"
    }
    
    // ✅ 상세 이미지가 있는지(미리보기에서 빈 슬롯 숨김용)
    private func hasDetailImage(at index: Int) -> Bool {
        if draft.detailImageDatas.indices.contains(index),
           !draft.detailImageDatas[index].isEmpty {
            return true
        }
        if draft.isModify,
           draft.detailImageUrls.indices.contains(index),
           !draft.detailImageUrls[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
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
        let userId = LoginInfoUtil.getUserId()
        let userNo = LoginInfoUtil.getUserNo()
        let systemType = String(Constants.SYSTEM_TYPE)

        
        let saleStatus: String = {
            if systemType == "1" { return "1" }   // 판매중
            return "0"                            // 승인요청(또는 기본)
        }()

        let product = ProductVo(
            productId: d.productId,
            userNo: userNo,
            title: d.name,
            description: d.detail,
            price: d.amount,
            categoryGroup: "R010610",
            categoryMid: d.categoryMid,
            categoryScls: d.categoryScls,
            saleStatus: saleStatus,
            areaGroup: "R010070",
            areaMid: d.areaMid,
            areaScls: d.areaScls,
            quantity: d.quantity,
            unitGroup: "R010620",
            unitCode: d.unitCode,
            desiredShippingDate: d.desiredShippingDate,
            registerNo: userNo,
            registDt: "",
            updusrNo: userNo,
            updtDt: "",
            imageUrl: nil,
            categoryMidNm: nil,
            categorySclsNm: nil,
            areaMidNm: nil,
            areaSclsNm: nil,
            unitCodeNm: nil,
            saleStatusNm: nil,
            userId: userId,
            wholesalerNo: nil,
            wholesalerId: nil,
            fav: nil,
            systemType: systemType,
            rejectReason: nil
        )

        var metas: [ProductImageVo] = []
        var images: [Data] = []

        func appendImage(data: Data, imageId: Int64?, represent: Int) {
            images.append(data)
            metas.append(
                ProductImageVo(
                    imageId: imageId,
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
