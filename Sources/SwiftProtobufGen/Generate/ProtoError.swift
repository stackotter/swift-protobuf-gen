import Foundation

enum ProtoError: LocalizedError {
  case unknownVariableType(String)
  case invalidArrayType(TypeDeclaration)
}
