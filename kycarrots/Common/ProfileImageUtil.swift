import UIKit

struct ProfileImageUtil {
    static func getLocalProfileImage() -> UIImage? {
        let url = getProfileImageUrl()
        if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
            return uiImage
        }
        return nil
    }
    
    static func getProfileImageUrl() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile_image.jpg")
    }
}
