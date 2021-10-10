struct ProtoMessage {
  var name: String
  var fields: [ProtoField]
  
  func toString() -> String {
    var string = "message \(name) {\n"
    for field in fields {
      string += field.toString() + "\n"
    }
    string += "}"
    return string
  }
}
