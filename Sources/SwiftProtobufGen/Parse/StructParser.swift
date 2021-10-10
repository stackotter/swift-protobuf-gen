import Foundation
import AST

class StructParser : ASTVisitor {
  var structs: [String: StructDeclaration] = [:]
  
  func visit(_ structDecl: AST.StructDeclaration) throws -> Bool {
    var properties: [PropertyDeclaration] = []
    for member in structDecl.members {
      if let property = try parsePropertyMember(member.textDescription) {
        properties.append(property)
      }
    }
    
    structs[structDecl.name.description] = StructDeclaration(name: structDecl.name.description, properties: properties)
    
    return true
  }
  
  func tokenize(_ text: String) -> [String] {
    var openBrackets: [String] = []
    var tokens: [String] = []
    var token = ""
    for c in text {
      if "{[(<".contains(c) {
        openBrackets.append(String(c))
      }
      
      // We can safely assume syntax is correct so just assume it's the correct closing bracket
      if "}])>".contains(c) {
        openBrackets.removeLast()
        token.append(c)
        tokens.append(token)
        token = ""
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
          case ":", ",", "(", ")", "{", "}":
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
  
  func parsePropertyMember(_ text: String) throws -> PropertyDeclaration? {
    let memberTypes: Set = ["var", "let", "func", "init"]
    let tokens = tokenize(text)
    
    var modifiers: [String] = []
    for (index, token) in tokens.enumerated() {
      if memberTypes.contains(token) {
        do {
          if let variable = try parsePropertyMember(modifiers, token, Array(tokens.dropFirst(index + 1))) {
            return variable
          }
        } catch {
          throw ParseError.failedToParseMember(text, error)
        }
        return nil
      } else {
        modifiers.append(token)
      }
    }
    
    return nil
  }
  
  func tokenizeType(_ text: String) -> [String] {
    var tokens: [String] = []
    var token = ""
    for c in text {
      switch c {
        case "<", ">", "[", "]", ",":
          if !token.isEmpty {
            tokens.append(token)
          }
          token = ""
          tokens.append(String(c))
        default:
          token.append(c)
      }
    }
    
    if !token.isEmpty {
      tokens.append(token)
    }
    
    return tokens
  }
  
  func parsePropertyMember(_ modifiers: [String], _ memberType: String, _ remainingTokens: [String]) throws -> PropertyDeclaration? {
    if let memberType = VariableType(rawValue: memberType) {
      var iterator = remainingTokens.makeIterator()
      guard let name = iterator.next() else {
        throw ParseError.missingVariableName
      }
      
      guard iterator.next() == ":" else {
        throw ParseError.missingTypeDeclaration
      }
      
      guard let typeText = iterator.next() else {
        throw ParseError.missingTypeDeclaration
      }
      
      let typeTokens = tokenizeType(typeText)
      let type = try parseType(typeTokens)
      
      // Ignore computed properties
      if let nextToken = iterator.next() {
        print("next token: \(nextToken)")
        if nextToken.starts(with: "{") {
          return nil
        }
      }
      
      return PropertyDeclaration(modifiers: modifiers, memberType: memberType, name: name, type: type)
    }
    
    return nil
  }
  
  func parseType(_ tokens: [String]) throws -> TypeDeclaration {
    var openBrackets: [String] = []
    var typeParameterTokens: [[String]] = []
    var currentTypeParameterTokens: [String]? = nil
    
    var iterator = tokens.makeIterator()
    guard let name = iterator.next() else {
      throw ParseError.emptyTypeDeclaration
    }
    
    if let nextToken = iterator.next() {
      if nextToken == "<" {
        openBrackets.append("<")
        
        // Read generic type parameters
      forLoop: for token in iterator {
        switch token {
          case "<":
            openBrackets.append(token)
          case ">":
            openBrackets.removeLast()
            
            if openBrackets.isEmpty {
              if let currentTypeParameter = currentTypeParameterTokens {
                typeParameterTokens.append(currentTypeParameter)
              }
              break forLoop
            }
          default:
            if token == "," && openBrackets.count == 1 {
              guard let typeParameter = currentTypeParameterTokens else {
                throw ParseError.invalidComma
              }
              
              typeParameterTokens.append(typeParameter)
              currentTypeParameterTokens = []
            }
            
            if currentTypeParameterTokens == nil {
              currentTypeParameterTokens = []
            }
            currentTypeParameterTokens?.append(token)
        }
      }
      }
    }
    
    guard openBrackets.isEmpty else {
      throw ParseError.lonelyOpeningBracket
    }
    
    var typeParameters: [TypeDeclaration] = []
    for tokens in typeParameterTokens {
      typeParameters.append(try parseType(tokens))
    }
    
    return TypeDeclaration(name: name, typeParameters: typeParameters)
  }
}
