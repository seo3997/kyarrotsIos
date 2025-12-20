import Foundation

enum StompFrame {

    static func connect(heartBeat: String = "0,0") -> String {
        // 서버에 따라 accept-version/host가 필요할 수 있는데,
        // Android에서 별 설정 없이 됐다면 이 정도로도 대부분 동작함
        return """
        CONNECT
        accept-version:1.2
        heart-beat:\(heartBeat)

        \u{0000}
        """
    }

    static func subscribe(id: String, destination: String) -> String {
        return """
        SUBSCRIBE
        id:\(id)
        destination:\(destination)
        ack:auto

        \u{0000}
        """
    }

    static func unsubscribe(id: String) -> String {
        return """
        UNSUBSCRIBE
        id:\(id)

        \u{0000}
        """
    }

    static func send(destination: String, body: String) -> String {
        // content-length는 생략 (서버가 tolerant하면 OK)
        return """
        SEND
        destination:\(destination)
        content-type:application/json;charset=utf-8

        \(body)\u{0000}
        """
    }
}
