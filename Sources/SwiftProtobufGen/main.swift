import Foundation
import ArgumentParser
import Parser
import Source

func terminate(_ message: String) -> Never {
  print(message)
  Foundation.exit(1)
}

struct SwiftProtobufGen: ParsableCommand {
  @Argument(help: "The directory containing swift source files with all the required types")
  var directory: String
  
  @Argument(help: "The type to create a protobuf message definition for (either an enum or a struct)")
  var typeName: String
  
  func run() {
    let directory = URL(fileURLWithPath: directory, isDirectory: true)
    
    // Parse required structs and enums
    do {
      let baseTypes: Set = [
        "Int", "Int64",
        "UInt", "UInt64",
        "Int32", "Int16", "Int8",
        "UInt32", "UInt16", "UInt8",
        "Bool", "String",
        "Array", "Set",
        "Optional"]
      
      var structs: [String: StructDeclaration] = [:]
      var enums: [String: EnumDeclaration] = [:]
      var allTypeDependencies: Set<String> = []
      
      var missingTypes: Set<String> = [typeName]
      
      while !missingTypes.isEmpty {
        let typeName = missingTypes.removeFirst()
        
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
          terminate("Failed to create directory enumerator")
        }
        
        var swiftFileOptional: URL?
        for case let file as URL in enumerator where file.lastPathComponent == "\(typeName).swift" {
          swiftFileOptional = file
          break
        }
        
        guard let swiftFile = swiftFileOptional else {
          terminate("Failed to find file for '\(typeName)' (should be called '\(typeName).swift')")
        }
        
        let sourceFile = try SourceReader.read(at: swiftFile.path)
        let parser = Parser(source: sourceFile)
        let topLevelDecl = try parser.parse()
        
        let structParser = StructParser()
        let enumParser = EnumParser()
        try _ = structParser.traverse(topLevelDecl)
        try _ = enumParser.traverse(topLevelDecl)
        
        for structDecl in structParser.structs {
          structs[structDecl.name] = structDecl
          allTypeDependencies.formUnion(structDecl.dependencies)
        }
        
        for enumDecl in enumParser.enums {
          enums[enumDecl.name] = enumDecl
        }
        
        missingTypes = allTypeDependencies
        missingTypes.subtract(baseTypes)
        missingTypes.subtract(structs.keys)
        missingTypes.subtract(enums.keys)
        
        if missingTypes.contains(typeName) {
          terminate("Failed to locate type '\(typeName)' in '\(typeName).swift'")
        }
      }
      
      // Create proto
      var protoFile = ProtoFile()
      var typesAdded: Set<String> = []
      var typesToAdd = [typeName]
      
      whileLoop: while !typesToAdd.isEmpty {
        let typeToAdd = typesToAdd[typesToAdd.count - 1]
        if let decl = structs[typeToAdd] {
          // If a dependency is not yet added to the proto file, skip this one for now and add it
          for dependency in decl.dependencies {
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
