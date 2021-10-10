import Foundation
import Parser
import Source

// Create test file
let tempDir = FileManager.default.temporaryDirectory
let tempFile = tempDir.appendingPathComponent("code.swift")
let testCode = """
struct Data {
  public var firstName: String
  private var lastName: String
  public var age: Int
  public var twiceAge: Int { age * 2 }
  public var friends: [String]
}
"""

// Parse test file
do {
  try testCode.write(to: tempFile, atomically: false, encoding: .utf8)
  let sourceFile = try SourceReader.read(at: tempFile.path)
  let parser = Parser(source: sourceFile)
  let topLevelDecl = try parser.parse()
  
  let visitor = StructParser()
  try _ = visitor.traverse(topLevelDecl)
  
  guard let structDeclaration = visitor.structs["Data"] else {
    print("Failed to find specified struct")
    Foundation.exit(1)
  }
  
  var file = ProtoFile()
  try file.add(structDeclaration)
  print(file.toString())
} catch {
  print("Failed to parse file: \(error)")
}
