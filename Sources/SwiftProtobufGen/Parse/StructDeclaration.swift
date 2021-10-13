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
  
  /// Returns all types used by this struct's variables.
  var dependencies: [String] {
    var types: [String] = []
    for property in properties {
      types.append(contentsOf: property.type.types)
    }
    return types
  }
}
