import Foundation

enum ParseError: LocalizedError {
  case failedToParseMember(String, Error)
  case missingVariableName
  case missingTypeDeclaration
  case typeIsGeneric
  case lonelyClosingBracket
  case lonelyOpeningBracket
  case squareBracketNotArray
  case invalidComma
  case invalidTypeParameter
  case emptyTypeDeclaration
}
