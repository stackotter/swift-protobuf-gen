import Foundation
import AST

class EnumParser: ASTVisitor {
  var enums: [EnumDeclaration] = []
  
  func visit(_ enumDecl: AST.EnumDeclaration) throws -> Bool {
    guard enumDecl.genericParameterClause == nil && enumDecl.genericWhereClause == nil else {
      print("warning: Skipping '\(enumDecl.name.description)' enum because it has generic type parameter")
      return true
    }
    
    print("Parsing enum '\(enumDecl.name.description)'")
    
    var cases: [String] = []
    for member in enumDecl.members {
      do {
        if let caseName = try parseCase(member.description) {
          cases.append(caseName)
        }
      } catch {
        print("error: failed to parse enum case '\(error)'")
        throw error
      }
    }
    
    enums.append(
      EnumDeclaration(
        name: enumDecl.name.description,
        cases: cases
      ))
    
    return true
  }
  
  func parseCase(_ text: String) throws -> String? {
    let tokens = tokenize(text)
    var iterator = tokens.makeIterator()
    
    guard let firstToken = iterator.next(), firstToken == "case" else {
      return nil
    }
    
    guard let name = iterator.next() else {
      throw EnumError.missingCaseName(text)
    }
    
    let nextToken = iterator.next()
    guard nextToken == nil || nextToken == "=" else {
      throw EnumError.foundEnumCaseAssociatedType(text)
    }
    
    return name
  }
  
  func tokenize(_ text: String) -> [String] {
    var openBrackets: [String] = []
    var tokens: [String] = []
    var token = ""
    for c in text {
      if "{[(<".contains(c) {
        openBrackets.append(String(c))
        
        if openBrackets.count == 1 {
          if !token.isEmpty {
            tokens.append(token)
            token = ""
          }
          tokens.append(String(token))
          continue
        }
      }
      
      // We can safely assume syntax is correct so just assume it's the correct closing bracket
      if "}])>".contains(c) {
        openBrackets.removeLast()
        token.append(c)
        if openBrackets.isEmpty {
          tokens.append(token)
          token = ""
        }
        continue
      }
      
      // Brackets and their contents count as one big token
      if !openBrackets.isEmpty {
        token.append(c)
      } else {
        switch c {
          case " ", "\t", "\n":
            if !token.isEmpty {
              tokens.append(token)
            }
            token = ""
          case "=", "(", ")":
            if !token.isEmpty {
              tokens.append(token)
            }
            token = ""
            tokens.append(String(c))
          default:
            token.append(c)
        }
      }
    }
    
    if !token.isEmpty {
      tokens.append(token)
    }
    
    return tokens
  }
}
