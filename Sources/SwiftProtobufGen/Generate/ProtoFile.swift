import Foundation

struct ProtoFile {
  var syntax = "proto3"
  var messages: [ProtoMessage] = []
  var messageNames: [String] {
    messages.map { $0.name }
  }
  
  /// - Returns: The generated contents of the proto file.
  func toString() -> String {
    var string = "syntax = \"\(syntax)\";"
    for message in messages {
      string += "\n\n" + message.toString()
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
          modifier: property.type.name == "Optional" ? .optional : nil,
          baseType: protoType,
          name: property.name.snakeCased(),
          index: index + 1
        ))
    }
    
    messages.append(message)
  }
  
  private mutating func protoType(for swiftType: TypeDeclaration) throws -> ProtoType {
    switch swiftType.name {
      case "Int", "Int64":
        return .int64
      case "UInt", "UInt64":
        return .uint64
      case "Int32", "Int16", "Int8":
        return .int32
      case "UInt32", "UInt16", "UInt8":
        return .uint32
      case "Bool":
        return .bool
      case "String":
        return .string
      case "Array", "Set":
        guard swiftType.typeParameters.count == 1, let elementType = swiftType.typeParameters.first else {
          throw ProtoError.invalidArrayType(swiftType)
        }
        let elementProtoType = try protoType(for: elementType)
        let messageName = try messageName(for: swiftType)
        if !messageNames.contains(messageName) {
          let message = ProtoMessage(
            name: messageName,
            fields: [
              ProtoField(modifier: .repeated, baseType: elementProtoType, name: "elements", index: 1)
            ])
          messages.append(message)
        }
        return .custom(messageName)
      case "Optional":
        guard swiftType.typeParameters.count == 1, let wrappedType = swiftType.typeParameters.first else {
          throw ProtoError.invalidOptionalType(swiftType)
        }
        return try protoType(for: wrappedType)
      default:
        if messageNames.contains(swiftType.name) {
          guard swiftType.typeParameters.isEmpty else {
            throw ProtoError.customTypeCantBeGeneric(swiftType)
          }
          return .custom(swiftType.name)
        }
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
