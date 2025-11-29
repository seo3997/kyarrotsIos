//
//  DashboardViewController.swift
//  kycarrots
//
//  Created by soohyun on 11/3/25.
//

import UIKit
import SideMenu

struct RecentProduct {
    let title: String
    let subInfo: String
}

class DashboardViewController: UITableViewController {
    
    @IBOutlet weak var headerCardView: UIView!
    
    @IBOutlet weak var CardView: UIView!
    private var items: [RecentProduct] = []
    
    override func viewDidLoad() {
       super.viewDidLoad()
       title = "대시보드"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(didTapHamburger)
        )
        
       print("VC type =", type(of: self))  //DashboardViewControllerTableViewController 나와야 함
       print("storyboard =", storyboard?.description as Any)
       print("headerCardView =", headerCardView as Any) // 여기서 nil이면 아래 1~4 진행
       print("UserId =", LoginInfoUtil.getUserId())  

        // 1) tableHeaderView로 ‘승격’
       let header = headerCardView!         // 로그상 nil 아님
       //header.removeFromSuperview()         // 혹시 TableView의 subview로 붙어있던 것 방지
       header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 200)
       tableView.tableHeaderView = header   // ←. 이 줄로 ‘진짜’ 헤더가 됨
       CardView.layer.cornerRadius = 12
       CardView.layer.borderWidth = 1
       CardView.layer.borderColor = UIColor.systemGray5.cgColor
       CardView.layer.shadowColor = UIColor.black.cgColor
       CardView.layer.shadowOpacity = 0.12
       CardView.layer.shadowOffset = CGSize(width: 0, height: 2)
       CardView.layer.shadowRadius = 4
       CardView.layer.masksToBounds = false
        // 테이블 기본
       tableView.separatorStyle = .none
       tableView.backgroundColor = .systemGroupedBackground
       tableView.rowHeight = UITableView.automaticDimension
       tableView.estimatedRowHeight = 60
 
        // 2) 데모 데이터
       items = [
           .init(title: "배추 500kg", subInfo: "용인시 처인구 / 6월 5일"),
           .init(title: "상추 200kg", subInfo: "수원시 영통구 / 6월 4일")
       ]

       // 3) 프로토타입 셀을 아직 안 만들었다면, 임시 기본 셀 등록
        /*
       tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        */
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    @objc private func didTapHamburger() {
        if let menu = SideMenuManager.default.leftMenuNavigationController {
            present(menu, animated: true, completion: nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func adjustTableHeaderSize() {
        guard let header = tableView.tableHeaderView else { return }
        header.setNeedsLayout()
        header.layoutIfNeeded()
        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if header.frame.height != size.height {
            var f = header.frame
            f.size.height = size.height
            header.frame = f
            tableView.tableHeaderView = header
        }
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecentProductCell.reuseID, for: indexPath) as! RecentProductCell
        let item = items[indexPath.row]
        cell.configure(title: item.title, subInfo: item.subInfo)
        cell.onTapButton = { [weak self] in
            guard let self else { return }
            print("처리중 탭: \(item.title)")
            // TODO: 상태변경/상세 화면 진입 등
        }
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
