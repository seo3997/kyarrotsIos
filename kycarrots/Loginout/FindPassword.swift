import Foundation


final class FindPassword {

    private let email: String
    private let service: AppService

    init(email: String, service: AppService) {
        self.email = email
        self.service = service
    }

    /// 서버 응답: "200", "601", "602", ...
    func find() async -> Int {
        do {
            // 서버에서 문자열 코드 받는 구조라고 가정
            let codeStr = (try await service.findPassword(email: email) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let code = Int(codeStr) else {
                return StaticDataInfo.RESULT_CODE_ERR
            }

            switch code {
            case StaticDataInfo.RESULT_CODE_200,
                 StaticDataInfo.RESULT_NO_USER,
                 StaticDataInfo.RESULT_PWD_ERR,
                 StaticDataInfo.RESULT_MEMBER_CODE_ERR,
                 StaticDataInfo.RESULT_NO_DATA,
                 StaticDataInfo.RESULT_NO_SOCAIL_DATA:
                return code

            default:
                return StaticDataInfo.RESULT_CODE_ERR
            }

        } catch {
            return StaticDataInfo.RESULT_CODE_ERR
        }
    }
}
