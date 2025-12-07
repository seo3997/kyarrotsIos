//
//  ProductDetailViewController.swift
//  kycarrots
//
//  Created by soo on 12/6/25.
//


//
//  ProductDetailViewController.swift
//  kycarrots
//
//  Created by soohyun on 12/06/25.
//

import UIKit

final class ProductDetailViewController: UIViewController {

    // MARK: - IBOutlets (스토리보드 연결)
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var productImageView: UIImageView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!

    // 아래는 필요하면 스토리보드에 더 연결해서 사용 (상품명, 가격 등)
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    // MARK: - Properties

    /// 안드로이드 CollapsingToolbarLayout 의 이미지 height 느낌
    private let headerBaseHeight: CGFloat = 260

    /// 어느 정도 스크롤되면 collapsed 로 본다
    private let navBarThreshold: CGFloat = 120

    /// 네비게이션바 배경용 overlay (알파만 조절)
    private var navBarOverlay: UIView?

    /// 예시용 상품 데이터 (실제론 서버에서 받은 모델 넣으면 됨)
    var productTitle: String?
    var productPriceText: String?
    var productAreaText: String?
    var productStatusText: String?
    var productImageURL: URL?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScrollView()
        setupHeaderView()
        setupNavBarAppearance()
        self.title = productTitle ?? "상품 상세"
        bindData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutNavBarOverlayIfNeeded()
    }
}

// MARK: - Setup

private extension ProductDetailViewController {

    func setupScrollView() {
        scrollView.delegate = self

        // 헤더가 네비바 뒤로 살짝 들어가 보이도록 inset 조정
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
    }

    func setupHeaderView() {
        headerHeightConstraint.constant = headerBaseHeight

        productImageView.contentMode = .scaleAspectFill
        productImageView.clipsToBounds = true
    }

    func setupNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // 1) 완전 투명 말고, 기본 배경 사용
        // appearance.configureWithTransparentBackground()
        appearance.configureWithDefaultBackground()

        // 2) 글자 색을 시스템 기본(label)로 → 흰/검 자동
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        navigationController?.navigationBar.tintColor = UIColor.label
    }
    
    func layoutNavBarOverlayIfNeeded() {
        guard let navBar = navigationController?.navigationBar else { return }

        if navBarOverlay == nil {
            let overlay = UIView(frame: navBar.bounds)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.backgroundColor = UIColor.systemGreen   // KyCarrots 대표색 등
            overlay.alpha = 0
            navBar.insertSubview(overlay, at: 0)
            navBarOverlay = overlay
        } else {
            navBarOverlay?.frame = navBar.bounds
        }
    }

    func bindData() {
        // 실제 프로젝트에서는 서버 모델에서 값 넣기
        titleLabel.text = productTitle ?? "상품 제목"
        priceLabel.text = productPriceText ?? "₩ 0"
        areaLabel.text = productAreaText ?? "지역 정보"
        statusLabel.text = productStatusText ?? "상태"

        // 이미지는 Kingfisher / Nuke 등으로 로딩 (여긴 placeholder)
        if let url = productImageURL {
            // 예: productImageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
            // 지금은 테스트용
            productImageView.image = UIImage(named: "placeholder")
        } else {
            productImageView.image = UIImage(named: "placeholder")
        }
    }
}

// MARK: - UIScrollViewDelegate (Parallax + Collapsing 효과)

extension ProductDetailViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        // 1) 패럴럭스 & 헤더 늘어나는 효과
        if offsetY < 0 {
            // 아래로 당길 때: 헤더 높이를 키워서 늘어나는 느낌
            headerHeightConstraint.constant = headerBaseHeight - offsetY
            productImageView.transform = .identity
        } else {
            // 위로 스크롤 할 때: 헤더는 줄어들다가 0 까지만
            headerHeightConstraint.constant = max(headerBaseHeight - offsetY, 0)

            // 패럴럭스: 이미지가 콘텐츠보다 조금 느리게 스크롤
            let parallaxRatio: CGFloat = 0.5
            productImageView.transform = CGAffineTransform(
                translationX: 0,
                y: -offsetY * parallaxRatio
            )
        }

        // 2) 네비바 배경 알파 + 타이틀 처리
        updateNavBar(for: offsetY)
    }

    private func updateNavBar(for offsetY: CGFloat) {
        // threshold 기준으로 alpha 계산 (0~1)
        let alpha = min(max((offsetY - navBarThreshold) / 80.0, 0), 1)

        navBarOverlay?.alpha = alpha

        // alpha 가 어느 정도 이상이면 collapsed title 표시
        /*
        if alpha > 0.5 {
            self.title = productTitle ?? "상품 상세"
        } else {
            self.title = ""
        }
         */
    }
}
