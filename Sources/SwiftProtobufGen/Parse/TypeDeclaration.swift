import Foundation

struct TypeDeclaration: CustomStringConvertible {
  var name: String
  var typeParameters: [TypeDeclaration]
  
  var description: String {
    var string = name
    if !typeParameters.isEmpty {
      let parameterStrings = typeParameters.map { $0.description }
      string += "<\(parameterStrings.joined(separator: ", "))>"
    }
    return string
  }
  
  /// All types involved with this type (as in including type parameters and their type parameters and so on).
  var types: [String] {
    var types = [name]
    for typeParameter in typeParameters {
      types.append(contentsOf: typeParameter.types)
    }
    return types
  }
}
