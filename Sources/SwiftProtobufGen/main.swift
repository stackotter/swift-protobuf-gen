import Foundation
import ArgumentParser
import Parser
import Source

func terminate(_ message: String) -> Never {
  print(message)
  Foundation.exit(1)
}

struct SwiftProtobufGen: ParsableCommand {
  @Argument(help: "The file containing the struct")
  var file: String
  
  @Argument(help: "The struct to create a protobuf message definition for*")
  var structName: String
  
  func run() {
    let url = URL(fileURLWithPath: file)
    guard FileManager.default.fileExists(atPath: url.path) else {
      terminate("File does not exist")
    }
    
    // Parse structs and enums in file
    do {
      print("Parsing file '\(url.lastPathComponent)'")
      let sourceFile = try SourceReader.read(at: url.path)
      let parser = Parser(source: sourceFile)
      let topLevelDecl = try parser.parse()
      
      let structParser = StructParser()
      let enumParser = EnumParser()
      try _ = structParser.traverse(topLevelDecl)
      try _ = enumParser.traverse(topLevelDecl)
      
      var typesInvolved: [String] = []
      var structs: [String: StructDeclaration] = [:]
      for structDecl in structParser.structs {
        structs[structDecl.name] = structDecl
        typesInvolved.append(contentsOf: structDecl.types)
      }
      
      // Create a list of base types (such as String and Int)
      // Find all variable types that are not base types. Check that they have been parsed
      // If they don't, throw an error for now. But eventually, search for those missing types in the specified directory.
      let baseTypes: Set = [
        "Int", "Int64",
        "UInt", "UInt64",
        "Int32", "Int16", "Int8",
        "UInt32", "UInt16", "UInt8",
        "Bool", "String",
        "Array", "Set",
        "Optional"]
      
      var types = Set(typesInvolved)
      types.subtract(baseTypes)
      types.subtract(Set(structs.keys))
      types.subtract(Set(enumParser.enums.map { $0.name }))
      
      if !types.isEmpty {
        terminate("Missing types: \(types)")
      }
      
      // Create proto
      var protoFile = ProtoFile()
      var typesAdded: Set<String> = []
      
      // We can safely add enums first and in any order because they can't depend on any types
      // (well they can, but if they do an error has already been thrown because they aren't
      // supported for putting into protobufs)
      for enumDecl in enumParser.enums {
        print("Adding enum '\(enumDecl.name)' to protobuf messages")
        protoFile.add(enumDecl)
        typesAdded.insert(enumDecl.name)
      }
      
      var structsToAdd = [structName]
      var deferred: [String] = []
      whileLoop: while !(structsToAdd.isEmpty && deferred.isEmpty) {
        if structsToAdd.isEmpty {
          structsToAdd = deferred
          deferred = []
        }
        
        let structToAdd = structsToAdd[structsToAdd.count - 1]
        let decl = structs[structToAdd]!
        let dependencies = decl.types
        
        for dependency in dependencies {
          if !typesAdded.contains(dependency) && !baseTypes.contains(dependency) {
            // Come back to this type later
            deferred.append(structToAdd)
            structsToAdd.remove(at: structsToAdd.count - 1)
            
            // Make sure the required type is processed soonish
            if deferred.contains(dependency) {
              structsToAdd.append(dependency)
              deferred.removeAll { $0 == dependency }
            } else if structs.keys.contains(dependency) && !structsToAdd.contains(dependency) {
              structsToAdd.append(dependency)
            }
            
            continue whileLoop
          }
        }
        
        print("Adding struct '\(decl.name)' to protobuf messages")
        try protoFile.add(decl)
        structsToAdd.remove(at: structsToAdd.count - 1)
        typesAdded.insert(structToAdd)
      }
      
      print("Added all types")
    } catch {
      print("Failed to parse file: \(error)")
    }
  }
}

SwiftProtobufGen.main()

// Create test file
//let tempDir = FileManager.default.temporaryDirectory
//let tempFile = tempDir.appendingPathComponent("code.swift")
//let testCode = """
//enum Response {
//  case yes
//  case no
//}
//
//struct Thing {
//  var name: String
//  var price: String?
//}
//
//struct Person {
//  var firstName: String
//  var lastName: String
//  var age: Int?
//  var favoriteThings: [Thing]?
//  var eulaResponse: Response
//
//  var twiceAge: Int { age * 2 }
//}
//"""
