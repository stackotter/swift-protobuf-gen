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
}
