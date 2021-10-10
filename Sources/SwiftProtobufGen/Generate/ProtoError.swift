import Foundation

enum ProtoError: LocalizedError {
  case unknownVariableType(String)
  case invalidArrayType(TypeDeclaration)
  case invalidOptionalType(TypeDeclaration)
  case customTypeCantBeGeneric(TypeDeclaration)
}
