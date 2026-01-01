// MakeAdImgRegiViewController.swift

import UIKit
import Kingfisher

/// Kotlin: KtMakeADImgRegiView 대응 (이미지 등록 화면)
/// - Draft에는 Data로 저장하고, 화면에서는 UIImage로 표시
/// - 수정 모드에서만 서버 URL(절대경로)로 이미지 표시 가능
/// - 사용자가 새 이미지를 선택하면 해당 슬롯의 URL/ID는 무효화(삭제)하여 Data가 우선이 되게 함
final class MakeAdImgRegiViewController: UIViewController,
                                         UIImagePickerControllerDelegate,
                                         UINavigationControllerDelegate {

    var onRequestPreview: (() -> Void)?

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    private let titleImageView = UIImageView()
    private let btnPickTitle = UIButton(type: .system)

    private var detailImageViews: [UIImageView] = []
    private var btnPickDetails: [UIButton] = []

    private let btnGoPreview = UIButton(type: .system)

    private var draft = MakeAdDraft()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
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

        let titleLabel = UILabel()
        titleLabel.text = "대표 이미지"
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        titleImageView.contentMode = .scaleAspectFill
        titleImageView.clipsToBounds = true
        titleImageView.layer.cornerRadius = 10
        titleImageView.backgroundColor = .systemGray5
        titleImageView.heightAnchor.constraint(equalToConstant: 180).isActive = true

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
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 10
            iv.backgroundColor = .systemGray6
            iv.heightAnchor.constraint(equalToConstant: 160).isActive = true

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

    // MARK: - Draft Binding

    /// 등록/수정 공통:
    /// - Data가 있으면 Data 표시
    /// - (수정일 때만) Data가 없으면 URL 표시
    func applyDraft(_ d: MakeAdDraft) {
        self.draft = d

        // 대표 이미지
        if let data = d.titleImageData, !data.isEmpty {
            titleImageView.kf.cancelDownloadTask()
            titleImageView.image = UIImage(data: data)
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

        // 상세 이미지 3장
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
    func collectDraft(into base: MakeAdDraft) -> MakeAdDraft {
        var d = base
        d.isChangeTitleImg = draft.isChangeTitleImg
        d.titleImageData = draft.titleImageData
        d.titleImageId = draft.titleImageId
        d.titleImageUrl = draft.titleImageUrl

        d.detailImageDatas = draft.detailImageDatas
        d.detailImageIds = draft.detailImageIds
        d.detailImageUrls = draft.detailImageUrls
        d.isChangeDetailImages = draft.isChangeDetailImages
        return d
    }

    // MARK: - Actions

    @objc private func onPreviewTapped() {
        onRequestPreview?()
    }

    @objc private func pickTitle() {
        presentPicker(for: .title)
    }

    @objc private func pickDetail(_ sender: UIButton) {
        presentPicker(for: .detail(index: sender.tag))
    }

    // MARK: - Picker

    private enum PickTarget {
        case title
        case detail(index: Int)
    }
    private var currentTarget: PickTarget?

    private func presentPicker(for target: PickTarget) {
        currentTarget = target
        let ac = UIAlertController(title: "이미지 선택", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            ac.addAction(UIAlertAction(title: "앨범", style: .default) { [weak self] _ in
                self?.openPicker(.photoLibrary)
            })
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            ac.addAction(UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
                self?.openPicker(.camera)
            })
        }
        ac.addAction(UIAlertAction(title: "취소", style: .cancel))

        if let pop = ac.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(ac, animated: true)
    }

    private func openPicker(_ type: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = type
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image = img else { return }
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }

        switch currentTarget {
        case .title:
            draft.titleImageData = data
            draft.isChangeTitleImg = true

            // ✅ 새 이미지 선택하면 서버 URL/ID 무효화
            draft.titleImageUrl = nil
            draft.titleImageId = nil

            titleImageView.kf.cancelDownloadTask()
            titleImageView.image = image

        case .detail(let index):
            // Data 슬롯 확보
            while draft.detailImageDatas.count <= index { draft.detailImageDatas.append(Data()) }
            draft.detailImageDatas[index] = data

            // 변경 플래그 확보
            while draft.isChangeDetailImages.count <= index { draft.isChangeDetailImages.append(false) }
            draft.isChangeDetailImages[index] = true

            // ✅ 해당 슬롯 서버 URL/ID 무효화
            while draft.detailImageUrls.count <= index { draft.detailImageUrls.append("") }
            draft.detailImageUrls[index] = ""

            while draft.detailImageIds.count <= index { draft.detailImageIds.append("") }
            draft.detailImageIds[index] = ""

            detailImageViews[index].kf.cancelDownloadTask()
            detailImageViews[index].image = image

        case .none:
            break
        }
    }
}
