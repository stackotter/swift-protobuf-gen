import Foundation
import Parser
import Source

// Create test file
let tempDir = FileManager.default.temporaryDirectory
let tempFile = tempDir.appendingPathComponent("code.swift")
let testCode = """
struct Thing {
  var name: String
  var price: String?
}

struct Friend {
  var fullName: String
  var eyeCount: UInt8
}

struct Person {
  var firstName: String
  var lastName: String
  var age: Int?
  var twiceAge: Int { age * 2 }
  var friends: [Friend]
  var favoriteThings: [Thing]?
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
  
  guard
    let friendStruct = visitor.structs.first(where: { $0.name == "Friend" }),
    let personStruct = visitor.structs.first(where: { $0.name == "Person" }),
    let thingStruct = visitor.structs.first(where: { $0.name == "Thing" })
  else {
    print("Failed to find specified struct")
    Foundation.exit(1)
  }
  
  var file = ProtoFile()
  try file.add(thingStruct)
  try file.add(friendStruct)
  try file.add(personStruct)
  print(file.toString())
} catch {
  print("Failed to parse file: \(error)")
}
