import Foundation
import ArgumentParser
import Parser
import Source

func terminate(_ message: String) -> Never {
  print(message)
  Foundation.exit(1)
}

struct SwiftProtobufGen: ParsableCommand {
  @Option(name: [.short, .customLong("dir")], help: "The directory containing swift source files with all the required types")
  var directory: String
  
  @Option(name: [.short, .customLong("type")], help: "The type to create a protobuf message definition for (either an enum or a struct)")
  var typeName: String
  
  @Option(name: [.short, .customLong("out")], help: "The directory to output protobuf stuff to")
  var outputDirectory: String
  
  func run() {
    let directory = URL(fileURLWithPath: directory, isDirectory: true)
    let outputDirectory = URL(fileURLWithPath: outputDirectory, isDirectory: true)
    
    do {
      // Locate and parse the required Swift types
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
      
      // Generate proto
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
      
      // Output proto
      print("Creating `generated.proto`")
      let proto = protoFile.toString()
      let protoOutFile = outputDirectory.appendingPathComponent("generated.proto")
      try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)
      try proto.write(to: protoOutFile, atomically: false, encoding: .utf8)
      
      // Run protobuf generate command
      print("Generating swift -> protobuf interface")
      let command = "protoc --swift_out=. generated.proto"
      guard Shell.getExitStatus(command, outputDirectory) == 0 else {
        terminate("Failed to run `\(command)` to generate swift -> protobuf interface code")
      }
      
      // Edit generated code
      print("Editing swift -> protobuf interface")
      
    } catch {
      print("Error: \(error)")
    }
  }
}

SwiftProtobufGen.main()
