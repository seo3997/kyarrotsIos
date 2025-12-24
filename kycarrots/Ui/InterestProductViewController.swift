//
//  InterestProductViewController.swift
//  kycarrots
//
//  Created by soo on 12/24/25.
//


import UIKit

class InterestProductViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    private var items: [AdItem] = []
    private var pageNo = 1
    private var isLoading = false
    private var isLastPage = false
    
    // 안드로이드의 AppServiceProvider 대응
    private let appService = AppServiceProvider.shared 

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "관심상품"
        setupTableView()
        fetchInterestList(isRefresh: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ 부모인 탭바 컨트롤러의 타이틀을 변경해야 상단 바에 반영됩니다.
        self.tabBarController?.title = "관심상품"
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib(nibName: "ProductTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: ProductTableViewCell.reuseIdentifier)
 
        // 셀 높이 자동 계산 (안드로이드 item_ad.xml 대응)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }

    // MARK: - API Call
    private func fetchInterestList(isRefresh: Bool = false) {
        guard !isLoading && !isLastPage else { return }
        
        if isRefresh {
            pageNo = 1
            isLastPage = false
        }
        
        isLoading = true
        loadingIndicator.startAnimating()
        
        // 토큰 가져오기 (기존 TokenUtil 활용)
        let token = TokenUtil.getToken() ?? ""

        Task {
            // 요청하신 API 호출
            let ads = await appService.getInterestItems(token: token, pageNo: pageNo)
            
            DispatchQueue.main.async {
                if ads.isEmpty {
                    if self.pageNo == 1 {
                        self.tableView.setEmptyMessage("관심상품이 없습니다.")
                    }
                    self.isLastPage = true
                } else {
                    self.tableView.restore()
                    if isRefresh {
                        self.items = ads
                    } else {
                        self.items.append(contentsOf: ads)
                    }
                    self.pageNo += 1
                    self.tableView.reloadData()
                }
                
                self.isLoading = false
                self.loadingIndicator.stopAnimating()
            }
        }
    }
}

// MARK: - TableView Delegate & DataSource
extension InterestProductViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductTableViewCell.reuseIdentifier, for: indexPath) as? ProductTableViewCell else {
            return UITableViewCell()
        }
        
        let item = items[indexPath.row]
        cell.configure(with: item) // 기존에 만들어둔 configure 재사용

        // 안드로이드 상세페이지 이동 처럼 '>' 모양 아이콘 추가
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // 무한 스크롤 구현 (안드로이드의 ScrollListener 대응)
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == items.count - 1 && !isLastPage {
            fetchInterestList(isRefresh: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ProductDetailVC") as! ProductDetailViewController
        vc.productId = Int64(item.productId ?? "") ?? 0
        vc.productUserId = item.userId ?? ""
        vc.productTitle = item.title ?? ""
        navigationController?.pushViewController(vc, animated: true)
        
    }
}

