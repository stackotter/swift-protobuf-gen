import Foundation

extension String {
  private static let snakeRegex = try! NSRegularExpression(pattern: "([a-z0-9])([A-Z])", options: [])
  
  func snakeCased() -> String {
    let range = NSRange(location: 0, length: self.count)
    return Self.snakeRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
  }
}
