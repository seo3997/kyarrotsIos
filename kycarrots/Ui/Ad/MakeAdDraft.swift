import Foundation

/// Android의 KtModifyADInfo 역할 (플랫폼 중립: UIImage 대신 Data)
struct MakeAdDraft {

    // mode
    var productId: String? = nil           // 수정이면 존재
    var adStatus: String? = nil

    // detail
    var name: String = ""
    var detail: String = ""
    var amount: String = ""
    var quantity: String = ""
    var unitCode: String? = nil
    var unitName: String? = nil
    var desiredShippingDate: String? = nil // yyyy-MM-dd

    // category (R010610)
    var categoryMid: String? = nil
    var categoryMidName: String? = nil
    var categoryScls: String? = nil
    var categorySclsName: String? = nil

    // area (R010070)
    var areaMid: String? = nil
    var areaMidName: String? = nil
    var areaScls: String? = nil
    var areaSclsName: String? = nil

    // sale status
    var saleStatus: String = "0"
    var systemType: String? = nil

    // images (✅ Draft는 Data로만 보관)
    var isChangeTitleImg: Bool = false
    var titleImageData: Data? = nil
    var titleImageId: String? = nil

    /// detail images (최대 3장 가정)
    var detailImageDatas: [Data] = []         // index=0..2
    var detailImageIds: [String] = []
    var isChangeDetailImages: [Bool] = []     // index=0..2

    // existing server urls (수정 프리뷰용)
    var titleImageUrl: String? = nil
    var detailImageUrls: [String] = []

    var isModify: Bool { !(productId ?? "").isEmpty }
}
