import Foundation

struct ProtoFile {
  var syntax = "proto3"
  
  var enums: [ProtoEnum] = []
  var enumNames: [String] {
    enums.map { $0.name }
  }
  
  var messages: [ProtoMessage] = []
  var messageNames: [String] {
    messages.map { $0.name }
  }
  
  var typeNames: [String] {
    var typesNames: [String] = enumNames
    typesNames.append(contentsOf: messageNames)
    return typesNames
  }
  
  /// - Returns: The generated contents of the proto file.
  func toString() -> String {
    var string = "syntax = \"\(syntax)\";"
    for protoEnum in enums {
      string += "\n\n" + protoEnum.toString()
    }
    for message in messages {
      string += "\n\n" + message.toString()
    }
    return string
  }
  
  func write(to file: URL) throws {
    try toString().write(to: file, atomically: false, encoding: .utf8)
  }
  
  // MARK: Struct
  
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
        if typeNames.contains(swiftType.name) {
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
  
  // MARK: Enum
  
  mutating func add(_ enumDeclaration: EnumDeclaration) {
    var cases: [ProtoEnumCase] = []
    for (index, name) in enumDeclaration.cases.enumerated() {
      cases.append(ProtoEnumCase(name: name, index: index))
    }
    
    enums.append(
      ProtoEnum(
        name: enumDeclaration.name,
        cases: cases
      ))
  }
}
