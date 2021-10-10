struct ProtoField {
  var isRepeated: Bool
  var baseType: ProtoType
  var name: String
  var index: Int
  
  func toString() -> String {
    var string = "  "
    if isRepeated {
      string += "repeated "
    }
    switch baseType {
      case .custom(let custom):
        string += custom + " "
      default:
        string += String(reflecting: baseType).split(separator: ".").last! + " "
    }
    string += name + " = \(index);"
    return string
  }
}
