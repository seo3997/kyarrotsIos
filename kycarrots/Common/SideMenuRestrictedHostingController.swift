import SwiftUI
import UIKit

class SideMenuRestrictedHostingController<Content: View>: UIHostingController<Content> {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide Back Button if needed and disable side menu
        self.navigationItem.setHidesBackButton(false, animated: false)
        self.setSideMenuEnabled(false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Re-enable side menu when leaving
        self.setSideMenuEnabled(true)
    }
}
