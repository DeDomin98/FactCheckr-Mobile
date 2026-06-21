import CryptoKit
import Foundation

func solvePoW(challenge: String, difficulty: Int) -> Int {
    let prefix = String(repeating: "0", count: difficulty)
    var nonce = 0
    while true {
        let input = Data((challenge + String(nonce)).utf8)
        let digest = SHA256.hash(data: input)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        if hex.hasPrefix(prefix) { return nonce }
        nonce += 1
    }
}
