struct ProtoEnumCase {
  var name: String
  var index: Int
  
  func toString() -> String {
    return "\(name.uppercased()) = \(index);"
  }
}
