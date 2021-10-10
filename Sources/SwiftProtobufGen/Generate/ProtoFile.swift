import Foundation

struct ProtoFile {
  var syntax = "proto3"
  var messages: [ProtoMessage] = []
  
  /// - Returns: The generated contents of the proto file.
  func toString() -> String {
    var string = "syntax = \"\(syntax)\";\n\n"
    for message in messages {
      string += message.toString() + "\n\n"
    }
    return string
  }
  
  func write(to file: URL) throws {
    try toString().write(to: file, atomically: false, encoding: .utf8)
  }
  
  /// Adds the message types for a Swift struct to the generator.
  /// - Parameter structDeclaration: Struct to add protobuf message types for.
  mutating func add(_ structDeclaration: StructDeclaration) throws {
    var message = ProtoMessage(name: structDeclaration.name, fields: [])
    
    for (index, property) in structDeclaration.properties.enumerated() {
      let protoType = try protoType(for: property.type)
      message.fields.append(
        ProtoField(
          isRepeated: false,
          baseType: protoType,
          name: property.name.snakeCased(),
          index: index + 1
        ))
    }
    
    messages.append(message)
  }
  
  private mutating func protoType(for swiftType: TypeDeclaration) throws -> ProtoType {
    switch swiftType.name {
      case "Int":
        return .int64
      case "String":
        return .string
      case "Array", "Set":
        guard swiftType.typeParameters.count == 1, let elementType = swiftType.typeParameters.first else {
          throw ProtoError.invalidArrayType(swiftType)
        }
        let elementProtoType = try protoType(for: elementType)
        let messageName = try messageName(for: swiftType)
        let message = ProtoMessage(
          name: messageName,
          fields: [
            ProtoField(isRepeated: true, baseType: elementProtoType, name: "elements", index: 1)
          ])
        messages.append(message)
        return .custom(messageName)
      default:
        throw ProtoError.unknownVariableType(swiftType.description)
    }
  }
  
  private func messageName(for swiftType: TypeDeclaration) throws -> String {
    switch swiftType.name {
      case "Array", "Set":
        guard let elementType = swiftType.typeParameters.first else {
          throw ProtoError.invalidArrayType(swiftType)
        }
        return try messageName(for: elementType) + "Array"
      default:
        return swiftType.name
    }
  }
}
