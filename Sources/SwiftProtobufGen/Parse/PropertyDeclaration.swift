import Foundation

struct PropertyDeclaration: CustomStringConvertible {
  var modifiers: [String]
  var memberType: VariableType
  var name: String
  var type: TypeDeclaration
  
  var description: String {
    var string = ""
    if !modifiers.isEmpty {
      string += modifiers.joined(separator: " ")
      string += " "
    }
    
    string += "\(memberType.rawValue) \(name): \(type)"
    
    return string
  }
}
