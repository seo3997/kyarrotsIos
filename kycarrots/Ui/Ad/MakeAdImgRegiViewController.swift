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

final class MakeAdImgRegiViewController: UIViewController,
                                         UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate {

    // MARK: - Callback
    var onRequestPreview: (() -> Void)?

    // MARK: - UI
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private let titleImageView = UIImageView()
    private let btnPickTitle = UIButton(type: .system)

    private var detailImageViews: [UIImageView] = []
    private var btnPickDetails: [UIButton] = []

    private let btnGoPreview = UIButton(type: .system)

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

        btnPickTitle.setTitle("대표 이미지 선택", for: .normal)
        btnPickTitle.addTarget(self, action: #selector(pickTitle), for: .touchUpInside)

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

            let b = UIButton(type: .system)
            b.setTitle("상세 이미지 \(i+1) 선택", for: .normal)
            b.tag = i
            b.addTarget(self, action: #selector(pickDetail(_:)), for: .touchUpInside)

            detailImageViews.append(iv)
            btnPickDetails.append(b)

            stack.addArrangedSubview(iv)
            stack.addArrangedSubview(b)
        }

        btnGoPreview.setTitle("미리보기", for: .normal)
        btnGoPreview.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btnGoPreview.heightAnchor.constraint(equalToConstant: 50).isActive = true
        btnGoPreview.layer.cornerRadius = 12
        btnGoPreview.layer.borderWidth = 1
        btnGoPreview.layer.borderColor = UIColor.systemGray4.cgColor
        btnGoPreview.addTarget(self, action: #selector(onPreviewTapped), for: .touchUpInside)

        stack.addArrangedSubview(btnGoPreview)
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

        // ✅ 상세 이미지 3장
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
    }

    /// Main에서 Preview 눌렀을 때 Draft 수집
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
        onRequestPreview?()
    }

    @objc private func pickTitle() {
        presentPicker(for: .title, sourceView: btnPickTitle)
    }

    @objc private func pickDetail(_ sender: UIButton) {
        presentPicker(for: .detail(index: sender.tag), sourceView: sender)
    }

    // MARK: - ActionSheet
    private func presentPicker(for target: PickTarget, sourceView: UIView) {
        currentTarget = target
        let ac = UIAlertController(title: "이미지 선택", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            ac.addAction(UIAlertAction(title: "앨범", style: .default) { [weak self] _ in
                // ✅ ActionSheet 닫힌 다음에 실행(실기기에서 안정화)
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
