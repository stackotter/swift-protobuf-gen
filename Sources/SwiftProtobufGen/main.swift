import Foundation
import Parser
import Source

// Create test file
let tempDir = FileManager.default.temporaryDirectory
let tempFile = tempDir.appendingPathComponent("code.swift")
let testCode = """
enum Response {
  case yes
  case no
}

struct Thing {
  var name: String
  var price: String?
}

struct Person {
  var firstName: String
  var lastName: String
  var age: Int?
  var favoriteThings: [Thing]?
  var eulaResponse: Response

  var twiceAge: Int { age * 2 }
}
"""

// Parse test file
do {
  try testCode.write(to: tempFile, atomically: false, encoding: .utf8)
  let sourceFile = try SourceReader.read(at: tempFile.path)
  let parser = Parser(source: sourceFile)
  let topLevelDecl = try parser.parse()
  
  let structParser = StructParser()
  let enumParser = EnumParser()
  try _ = structParser.traverse(topLevelDecl)
  try _ = enumParser.traverse(topLevelDecl)
  
  let structs = structParser.structs
  let enums = enumParser.enums
  
  guard
    let personStruct = structs.first(where: { $0.name == "Person" }),
    let thingStruct = structs.first(where: { $0.name == "Thing" }),
    let responseEnum = enums.first(where: { $0.name == "Response" })
  else {
    print("Failed to find specified struct")
    Foundation.exit(1)
  }
  
  var file = ProtoFile()
  file.add(responseEnum)
  try file.add(thingStruct)
  try file.add(personStruct)
  print(file.toString())
} catch {
  print("Failed to parse file: \(error)")
}
