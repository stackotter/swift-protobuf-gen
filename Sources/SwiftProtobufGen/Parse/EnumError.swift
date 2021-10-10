import Foundation

enum EnumError: LocalizedError {
  case missingCaseName(String)
  case foundEnumCaseAssociatedType(String)
}
