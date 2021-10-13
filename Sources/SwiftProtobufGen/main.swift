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
  
  @Argument(help: "The type to create a protobuf message definition for (either an enum or a struct)")
  var typeName: String
  
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
      
      var allTypeDependencies: [String] = []
      var structs: [String: StructDeclaration] = [:]
      for structDecl in structParser.structs {
        structs[structDecl.name] = structDecl
        allTypeDependencies.append(contentsOf: structDecl.types)
      }
      
      var enums: [String: EnumDeclaration] = [:]
      for enumDecl in enumParser.enums {
        enums[enumDecl.name] = enumDecl
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
      
      var missingTypes = Set(allTypeDependencies)
      missingTypes.subtract(baseTypes)
      missingTypes.subtract(structs.keys)
      missingTypes.subtract(enums.keys)
      
      if !missingTypes.isEmpty {
        terminate("Missing types: \(missingTypes)")
      }
      
      // Create proto
      var protoFile = ProtoFile()
      var typesAdded: Set<String> = []
      var typesToAdd = [typeName]
      
      whileLoop: while !typesToAdd.isEmpty {
        let typeToAdd = typesToAdd[typesToAdd.count - 1]
        if let decl = structs[typeToAdd] {
          let dependencies = decl.types
          
          // If a dependency is not yet added to the proto file, skip this one for now and add it
          for dependency in dependencies {
            if !typesAdded.contains(dependency) && !baseTypes.contains(dependency) {
              typesToAdd.removeAll { $0 == dependency }
              typesToAdd.append(dependency)
              continue whileLoop
            }
          }
          
          print("Adding struct '\(decl.name)' to protobuf messages")
          try protoFile.add(decl)
        } else if let decl = enums[typeToAdd] {
          protoFile.add(decl)
        } else {
          terminate("Can't find type '\(typeToAdd)'")
        }
        
        typesToAdd.remove(at: typesToAdd.count - 1)
        typesAdded.insert(typeToAdd)
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
