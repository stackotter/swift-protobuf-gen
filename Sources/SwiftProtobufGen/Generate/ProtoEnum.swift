struct ProtoEnum {
  var name: String
  var cases: [ProtoEnumCase]
  
  func toString() -> String {
    var string = "enum \(name) {\n"
    for enumCase in cases {
      string += "  " + enumCase.toString() + "\n"
    }
    string += "}"
    return string
  }
}
