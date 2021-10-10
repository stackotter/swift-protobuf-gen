import Foundation

struct StructDeclaration: CustomStringConvertible {
  var name: String
  var properties: [PropertyDeclaration]
  
  var description: String {
    var string = "struct \(name) {\n"
    for property in properties {
      string += "  \(property)\n"
    }
    string += "}"
    return string
  }
}
