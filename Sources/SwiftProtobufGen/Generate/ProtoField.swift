struct ProtoField {
  var modifier: ProtoFieldModifier?
  var baseType: ProtoType
  var name: String
  var index: Int = 1
  
  func toString() -> String {
    var string = "  "
    if let modifier = modifier {
      string += modifier.rawValue + " "
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
