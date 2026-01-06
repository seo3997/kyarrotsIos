//
//  MakeAdImgRegiViewController.swift
//  kycarrots
//
//  ✅ 수정모드에서 이미지 교체해도 titleImageId/detailImageIds 유지
//  ✅ Data 우선 표시, (수정일 때만) Data 없으면 URL 표시
//  ✅ collectDraft 시 내부 draft에 id가 없으면 base 값 유지(덮어쓰기 방지)
//  ✅ 앨범 권한 팝업/열기 안정화: Photos 권한 체크 + ActionSheet 후 딜레이 + MainThread present
//

import UIKit
import Kingfisher
import Photos
import AVFoundation


/// ✅ Android처럼 "빈 이미지 슬롯" 표시(플러스 아이콘 + 안내 문구)
final class EmptyImageOverlayView: UIView {

    private let iconView = UIImageView()
    private let textLabel = UILabel()

    init(text: String) {
        super.init(frame: .zero)
        setup(text: text)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(text: "")
    }

    private func setup(text: String) {
        isUserInteractionEnabled = false // 탭은 아래 UIImageView가 받게

        backgroundColor = UIColor.systemGray6
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        layer.cornerRadius = 12
        clipsToBounds = true

        iconView.image = UIImage(systemName: "photo.badge.plus")
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor.systemGray2

        textLabel.text = text
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.systemGray2
        textLabel.numberOfLines = 2
        textLabel.font = .systemFont(ofSize: 16, weight: .medium)

        let stack = UIStackView(arrangedSubviews: [iconView, textLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}

final class MakeAdImgRegiViewController: UIViewController,
                                         UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate {

    // MARK: - Callback
    var onRequestPreview: (() -> Void)?
    var onRequestGoDetailTab: (() -> Void)?
    
    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private let titleImageView = UIImageView()
    private let btnPickTitle = UIButton(type: .system)

    private var titleOverlay: EmptyImageOverlayView?
    private var isTitleDeleted: Bool = false

    private var detailImageViews: [UIImageView] = []
    private var btnPickDetails: [UIButton] = []

    private var detailOverlays: [EmptyImageOverlayView] = []

    private let btnGoPreview = UIButton(type: .system)

    // ✅ Android처럼: 상세 이미지 슬롯은 '추가' 버튼 눌러야 나타남(0~3)
    private var detailCount: Int = 0

    // ✅ 하단 이전/다음(다음=미리보기)
    private let bottomBar = UIStackView()
    private let btnPrev = UIButton(type: .system)
    private let btnNext = UIButton(type: .system)

    // MARK: - State
    private var draft = MakeAdDraft()

    // MARK: - Picker
    private enum PickTarget {
        case title
        case detail(index: Int)
    }
    private var currentTarget: PickTarget?

    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        refreshAllOverlays()
    }

    // MARK: - UI Setup
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

        let titleLabel = UILabel()
        titleLabel.text = "대표 이미지"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        configImageView(titleImageView, height: 180, bg: .systemGray5)

        // ✅ 대표 이미지 탭으로 선택/변경
        titleImageView.isUserInteractionEnabled = true
        titleImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapTitleImage)))

        // ✅ 대표 이미지 빈 슬롯 오버레이
        let tOv = EmptyImageOverlayView(text: "대표 이미지")
        titleImageView.addSubview(tOv)
        tOv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tOv.leadingAnchor.constraint(equalTo: titleImageView.leadingAnchor),
            tOv.trailingAnchor.constraint(equalTo: titleImageView.trailingAnchor),
            tOv.topAnchor.constraint(equalTo: titleImageView.topAnchor),
            tOv.bottomAnchor.constraint(equalTo: titleImageView.bottomAnchor)
        ])
        titleOverlay = tOv

        // ✅ 대표 이미지는 이미지(썸네일) 탭으로 변경/삭제하고, 버튼은 '광고세부 이미지 추가'로 사용
        btnPickTitle.setTitle("광고세부 이미지 추가", for: UIControl.State.normal)
        btnPickTitle.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btnPickTitle.backgroundColor = UIColor.systemTeal
        btnPickTitle.setTitleColor(.white, for: .normal)
        btnPickTitle.layer.cornerRadius = 10
        btnPickTitle.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        btnPickTitle.addTarget(self, action: #selector(onTapAddDetail), for: .touchUpInside)


        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(titleImageView)
        stack.addArrangedSubview(btnPickTitle)

        let detailLabel = UILabel()
        detailLabel.text = "상세 이미지 (최대 3장)"
        detailLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        stack.addArrangedSubview(detailLabel)

        for i in 0..<3 {
            let iv = UIImageView()
            configImageView(iv, height: 160, bg: .systemGray6)

            // ✅ 이미지 탭으로 선택/변경
            iv.tag = i
            iv.isUserInteractionEnabled = true
            iv.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapDetailImage(_:))))

            // ✅ 상세 이미지 빈 슬롯 오버레이
            let dOv = EmptyImageOverlayView(text: "광고세부 이미지")
            iv.addSubview(dOv)
            dOv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dOv.leadingAnchor.constraint(equalTo: iv.leadingAnchor),
                dOv.trailingAnchor.constraint(equalTo: iv.trailingAnchor),
                dOv.topAnchor.constraint(equalTo: iv.topAnchor),
                dOv.bottomAnchor.constraint(equalTo: iv.bottomAnchor)
            ])
            detailOverlays.append(dOv)

            // ✅ 처음엔 상세 슬롯 숨김(추가 버튼 눌러야 표시)
            iv.isHidden = true

            detailImageViews.append(iv)
            stack.addArrangedSubview(iv)
        }

        // ✅ 하단 이전/다음(다음=미리보기)
        bottomBar.axis = .horizontal
        bottomBar.spacing = 12
        bottomBar.distribution = .fillEqually

        btnPrev.setTitle("이전", for: UIControl.State.normal)
        btnPrev.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btnPrev.backgroundColor = UIColor.systemBrown
        btnPrev.setTitleColor(.white, for: .normal)
        btnPrev.layer.cornerRadius = 10
        btnPrev.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        btnPrev.addTarget(self, action: #selector(onPrevTapped), for: .touchUpInside)

        btnNext.setTitle("다음", for: UIControl.State.normal)
        btnNext.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btnNext.backgroundColor = UIColor.systemBlue
        btnNext.setTitleColor(.white, for: .normal)
        btnNext.layer.cornerRadius = 10
        btnNext.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        btnNext.addTarget(self, action: #selector(onPreviewTapped), for: .touchUpInside)

        bottomBar.addArrangedSubview(btnPrev)
        bottomBar.addArrangedSubview(btnNext)
        stack.addArrangedSubview(bottomBar)
    }

    private func configImageView(_ iv: UIImageView, height: CGFloat, bg: UIColor) {
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor = bg
        iv.heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    // MARK: - Draft Binding

    /// 등록/수정 공통:
    /// - Data가 있으면 Data 표시
    /// - (수정일 때만) Data가 없으면 URL 표시
    func applyDraft(_ d: MakeAdDraft) {
        self.draft = d
        // draft 적용 시 삭제 플래그는 URL/Data 기준으로 다시 판단 (삭제를 했으면 titleImageUrl을 비우도록 되어 있음)
        isTitleDeleted = false

        // ✅ 배열 길이 보정(수정모드에서 URL만 있고 배열이 짧으면 슬롯 계산이 틀어짐)
        ensureDetailArraysSize3()

        // ✅ 대표 이미지
        if let data = d.titleImageData, !data.isEmpty, let img = UIImage(data: data) {
            titleImageView.kf.cancelDownloadTask()
            titleImageView.image = img
        } else if d.isModify,
                  let urlStr = d.titleImageUrl,
                  !urlStr.isEmpty,
                  let url = URL(string: urlStr) {

            titleImageView.kf.indicatorType = .activity
            titleImageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholder"),
                options: [.transition(.fade(0.2)), .cacheOriginalImage]
            )
        } else {
            titleImageView.kf.cancelDownloadTask()
            titleImageView.image = UIImage(named: "placeholder")
        }

        // ✅ 상세 이미지 3장 (Data 우선, 수정일 때만 URL fallback)
        for i in 0..<detailImageViews.count {
            if d.detailImageDatas.indices.contains(i),
               !d.detailImageDatas[i].isEmpty,
               let img = UIImage(data: d.detailImageDatas[i]) {

                detailImageViews[i].kf.cancelDownloadTask()
                detailImageViews[i].image = img
                continue
            }

            if d.isModify,
               d.detailImageUrls.indices.contains(i),
               !d.detailImageUrls[i].isEmpty,
               let url = URL(string: d.detailImageUrls[i]) {

                detailImageViews[i].kf.indicatorType = .activity
                detailImageViews[i].kf.setImage(
                    with: url,
                    placeholder: UIImage(named: "placeholder"),
                    options: [.transition(.fade(0.2)), .cacheOriginalImage]
                )
            } else {
                detailImageViews[i].kf.cancelDownloadTask()
                detailImageViews[i].image = UIImage(named: "placeholder")
            }
        }

        // ✅ 실제로 존재하는 상세이미지만큼만 슬롯 표시 (Android와 동일)
        detailCount = 0
        for i in 0..<detailImageViews.count {
            let has = hasImage(for: .detail(index: i))
            if has { detailCount = max(detailCount, i + 1) }
        }
        for i in 0..<detailImageViews.count {
            detailImageViews[i].isHidden = (i >= detailCount)
        }

        refreshAllOverlays()
    }

    /// Main에서 Preview 눌렀을 때 Draft 수집눌렀을 때 Draft 수집
    /// ✅ 내부 draft의 ID가 nil/빈값이면 base 값을 유지(덮어쓰기 방지)
    func collectDraft(into base: MakeAdDraft) -> MakeAdDraft {
        var d = base

        // 대표
        d.isChangeTitleImg = draft.isChangeTitleImg
        d.titleImageData = draft.titleImageData
        d.titleImageUrl = draft.titleImageUrl

        if let id = draft.titleImageId, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            d.titleImageId = id
        }

        // 상세
        d.detailImageDatas = draft.detailImageDatas
        d.isChangeDetailImages = draft.isChangeDetailImages

        if !draft.detailImageIds.isEmpty {
            d.detailImageIds = draft.detailImageIds
        }
        if !draft.detailImageUrls.isEmpty {
            d.detailImageUrls = draft.detailImageUrls
        }

        return d
    }

    // MARK: - Actions
    @objc private func onPreviewTapped() {
        // ✅ 대표 이미지는 미리보기 시 필수
        guard hasTitleImageForPreview() else {
            let ac = UIAlertController(title: "대표 이미지 필요",
                                       message: "미리보기를 보려면 대표 이미지를 먼저 등록해주세요.",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "확인", style: .default))
            present(ac, animated: true)
            return
        }
        onRequestPreview?()
    }

    @objc private func onPrevTapped() {
        // ✅ 탭1(상세정보: MakeAdDetailViewController)로 전환
        if let cb = onRequestGoDetailTab {
            cb()
            return
        }

        // fallback: 네비게이션 구조면 뒤로
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    @objc private func onTapTitleImage() {
        presentPicker(for: .title, sourceView: titleImageView)
    }

    @objc private func onTapDetailImage(_ gr: UITapGestureRecognizer) {
        guard let iv = gr.view as? UIImageView else { return }
        // 숨김 슬롯은 무시
        if iv.isHidden { return }
        presentPicker(for: .detail(index: iv.tag), sourceView: iv)
    }

    @objc private func onTapAddDetail() {
        // ✅ 최대 3장까지, 버튼 눌러서 슬롯 생성
        guard detailCount < 3 else {
            let ac = UIAlertController(title: nil, message: "이미지는 최대 3장까지 추가할 수 있어요.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "확인", style: .default))
            present(ac, animated: true)
            return
        }

        let idx = detailCount

        // 다음 슬롯 표시
        detailImageViews[idx].isHidden = false

        // ✅ 처음 추가 순간에도 placeholder + 오버레이가 바로 보이게
        detailImageViews[idx].kf.cancelDownloadTask()
        detailImageViews[idx].image = UIImage(named: "placeholder")
        refreshDetailOverlay(index: idx)

        // 배열 길이도 맞춰두면 이후 선택/삭제에서 안전
        ensureDetailSlots(upto: idx)

        detailCount += 1
    }

    // MARK: - Image State Helpers
    private func hasImage(for target: PickTarget) -> Bool {
        switch target {
        case .title:
            if let data = draft.titleImageData, !data.isEmpty { return true }
            let url = (draft.titleImageUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return draft.isModify && !url.isEmpty

        case .detail(let index):
            // ✅ data가 있으면 urls 길이와 무관하게 "있음" 처리
            if draft.detailImageDatas.indices.contains(index) {
                let data = draft.detailImageDatas[index]
                if !data.isEmpty { return true }
            }

            // ✅ 수정모드에서만 URL fallback
            if draft.isModify, draft.detailImageUrls.indices.contains(index) {
                let url = draft.detailImageUrls[index].trimmingCharacters(in: .whitespacesAndNewlines)
                return !url.isEmpty
            }
            return false
        }
    }

    /// ✅ 미리보기 진입 시 대표 이미지는 필수(수정모드에서 삭제했다면 불가)
    private func hasTitleImageForPreview() -> Bool {
        if isTitleDeleted { return false }
        return hasImage(for: .title)
    }

    private func refreshTitleOverlay() {
        let has = hasImage(for: .title) && !isTitleDeleted
        titleOverlay?.isHidden = has
    }

    private func refreshDetailOverlay(index: Int) {
        guard detailOverlays.indices.contains(index),
              detailImageViews.indices.contains(index) else { return }

        let viewHidden = detailImageViews[index].isHidden
        let has = hasImage(for: .detail(index: index))

        // ✅ 슬롯이 보이는 상태 + 이미지 없음 => 오버레이(플러스/문구) 표시
        detailOverlays[index].isHidden = viewHidden || has
    }

    private func refreshAllOverlays() {
        refreshTitleOverlay()
        for i in 0..<min(detailOverlays.count, detailImageViews.count) {
            refreshDetailOverlay(index: i)
        }
    }

    private func presentPicker(for target: PickTarget, sourceView: UIView) {
        currentTarget = target
        let ac = UIAlertController(title: "이미지 선택", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            ac.addAction(UIAlertAction(title: "앨범", style: .default) { [weak self] _ in
                // ActionSheet 닫힌 다음 실행(실기기 안정화)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.openPhotoLibraryWithPermission()
                }
            })
        }

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            ac.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.openCameraWithPermission()
                }
            })
        }

        // ✅ 삭제(이미지 있을 때만)
        if hasImage(for: target) {
            ac.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.confirmDelete(for: target, sourceView: sourceView)
            })
        }

        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad crash 방지
        if let pop = ac.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
        }

        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }

    // MARK: - Delete Image

    private func confirmDelete(for target: PickTarget, sourceView: UIView) {
        let alert = UIAlertController(
            title: "이미지 삭제",
            message: "선택한 이미지를 삭제할까요?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteImage(for: target)
        })

        present(alert, animated: true)
    }
    private func ensureDetailArraysSize3() {
        // draft가 항상 3칸을 갖도록 보정 (out of range 방지)
        if draft.detailImageDatas.count < 3 {
            draft.detailImageDatas += Array(repeating: Data(), count: 3 - draft.detailImageDatas.count)
        }
        if draft.detailImageUrls.count < 3 {
            draft.detailImageUrls += Array(repeating: "", count: 3 - draft.detailImageUrls.count)
        }
        if draft.detailImageIds.count < 3 {
            draft.detailImageIds += Array(repeating: "", count: 3 - draft.detailImageIds.count)
        }
        if draft.isChangeDetailImages.count < 3 {
            draft.isChangeDetailImages += Array(repeating: false, count: 3 - draft.isChangeDetailImages.count)
        }
    }
    private func deleteImage(for target: PickTarget) {
        switch target {

        case .title:
            draft.titleImageData = nil
            draft.titleImageUrl = ""
            draft.isChangeTitleImg = true
            isTitleDeleted = true

            titleImageView.kf.cancelDownloadTask()
            titleImageView.image = UIImage(named: "placeholder") // 리소스명 확인!
            refreshAllOverlays()

        case .detail(let index):
            // ✅ 슬롯 범위/상태 방어
            guard index >= 0, index < 3 else { return }
            guard index < detailCount else { return } // 현재 보이는 슬롯 안에서만 삭제

            ensureDetailArraysSize3()

            // ✅ 중간 삭제면 앞으로 당김
            if detailCount > 1, index < (detailCount - 1) {
                for j in index..<(detailCount - 1) {
                    draft.detailImageDatas[j] = draft.detailImageDatas[j + 1]
                    draft.detailImageUrls[j] = draft.detailImageUrls[j + 1]
                    draft.detailImageIds[j] = draft.detailImageIds[j + 1]
                    draft.isChangeDetailImages[j] = true

                    detailImageViews[j].kf.cancelDownloadTask()
                    detailImageViews[j].image = detailImageViews[j + 1].image
                }
            }

            // 마지막 칸 비우기
            let last = detailCount - 1
            draft.detailImageDatas[last] = Data()
            draft.detailImageUrls[last] = ""
            draft.detailImageIds[last] = ""
            draft.isChangeDetailImages[last] = true

            detailImageViews[last].kf.cancelDownloadTask()
            detailImageViews[last].image = UIImage(named: "placeholder")

            // 슬롯 수 줄이고 마지막 숨김
            detailCount = max(0, detailCount - 1)
            for i in 0..<detailImageViews.count {
                detailImageViews[i].isHidden = (i >= detailCount)
            }

            refreshAllOverlays()
        }
    }
    // MARK: - Permission Gate

    private func openPhotoLibraryWithPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            openPicker(.photoLibrary)

        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if newStatus == .authorized || newStatus == .limited {
                        self.openPicker(.photoLibrary)
                    } else {
                        self.showGoSettingsAlert("사진 접근 권한이 필요합니다.")
                    }
                }
            }

        case .denied, .restricted:
            showGoSettingsAlert("사진 접근이 비활성화되어 있습니다.\n설정에서 사진 권한을 허용해 주세요.")

        @unknown default:
            showGoSettingsAlert("사진 권한 상태를 확인할 수 없습니다.")
        }
    }

    private func openCameraWithPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            openPicker(.camera)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if ok {
                        self.openPicker(.camera)
                    } else {
                        self.showGoSettingsAlert("카메라 접근 권한이 필요합니다.")
                    }
                }
            }

        case .denied, .restricted:
            showGoSettingsAlert("카메라 접근이 비활성화되어 있습니다.\n설정에서 카메라 권한을 허용해 주세요.")

        @unknown default:
            showGoSettingsAlert("카메라 권한 상태를 확인할 수 없습니다.")
        }
    }

    private func showGoSettingsAlert(_ msg: String) {
        let ac = UIAlertController(title: "권한 필요", message: msg, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }

    // MARK: - UIImagePicker
    private func openPicker(_ type: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = type
        picker.delegate = self
        picker.allowsEditing = true

        DispatchQueue.main.async {
            self.present(picker, animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
        }
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
        }

        let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image = img else { return }
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }

        switch currentTarget {
        case .title:
            draft.titleImageData = data
            draft.isChangeTitleImg = true
            // ✅ 수정 모드에서도 ID는 유지(절대 nil로 만들지 않음)

            titleImageView.kf.cancelDownloadTask()
            titleImageView.image = image

        case .detail(let index):
            ensureDetailSlots(upto: index)

            draft.detailImageDatas[index] = data
            draft.isChangeDetailImages[index] = true
            // ✅ 수정 모드에서도 ID는 유지(절대 ""로 overwrite 하지 않음)

            detailImageViews[index].kf.cancelDownloadTask()
            detailImageViews[index].image = image

            refreshDetailOverlay(index: index)

        case .none:
            break
        }
    }

    // MARK: - Helpers (index alignment)
    /// detailImageDatas / isChangeDetailImages 배열 길이를 index까지 맞춤
    /// (IDs/URLs은 수정모드에서 기존값 유지가 중요하므로 "늘릴 때만" 기본값을 추가하고, 기존 값은 건드리지 않음)
    private func ensureDetailSlots(upto index: Int) {
        while draft.detailImageDatas.count <= index { draft.detailImageDatas.append(Data()) }
        while draft.isChangeDetailImages.count <= index { draft.isChangeDetailImages.append(false) }

        // ids/urls는 applyDraft로 들어온 길이가 0일 수도 있으니 "길이만" 맞춰줌
        while draft.detailImageIds.count <= index { draft.detailImageIds.append("") }
        while draft.detailImageUrls.count <= index { draft.detailImageUrls.append("") }
        // ⚠️ 여기서 append한 ""는 신규 슬롯용 기본값.
        // 기존 슬롯의 값(특히 수정모드 id/url)은 절대 overwrite 하지 않음.
    }
}
