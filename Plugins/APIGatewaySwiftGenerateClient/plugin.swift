import PackagePlugin
import Foundation

private let targetSuffix = "Client"

enum PluginError: Error {
    case unknownModelPackageDependency(packageName: String)
    case unknownModelTargetDependency(packageName: String, targetName: String)
    case sourceModuleTargetRequired(packageName: String, targetName: String, type: Target.Type)
    case unknownModelFilePath(packageName: String, targetName: String, fileName: String)
    case missingConfigFile(expectedPath: String)
    case missingModelLocation(target: String)
}

@main
struct APIGatewaySwiftGenerateClientPlugin: BuildToolPlugin {
    struct ModelLocation: Decodable {
        let modelProductDependency: String?
        let modelTargetDependency: String?
        let modelFilePath: String
    }
    
    struct ModelLocations: Decodable {
        let `default`: ModelLocation?
        let targetMap: [String: ModelLocation]
        
        enum CodingKeys: String, CodingKey {
            case `default`
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.`default` = try values.decodeIfPresent(ModelLocation.self, forKey: .default)
            self.targetMap = try [String: ModelLocation].init(from: decoder)
        }
    }
    
    struct ModelTargets: Decodable {
        let `default`: ModelTarget?
        let targetMap: [String: ModelTarget]
        
        enum CodingKeys: String, CodingKey {
            case `default`
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.`default` = try values.decodeIfPresent(ModelTarget.self, forKey: .default)
            self.targetMap = try [String: ModelTarget].init(from: decoder)
        }
    }
    
    enum ClientConfigurationType: String, Codable {
        case configurationObject = "CONFIGURATION_OBJECT"
        case generator = "GENERATOR"
    }
    
    struct ModelTarget: Decodable {
        let modelTargetName: String?
    }
    
    struct APIGatewayClientSwiftCodeGen: Decodable {
        let baseName: String
        let modelLocations: ModelLocations?
        let clientConfigurationType: ClientConfigurationType?
        let modelTargets: ModelTargets?
    }
    
    /// This plugin's implementation returns a single build command which
    /// calls `APIGatewayClientGenerate` to generate the service client.
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // get the generator tool
        let serviceModelSwiftAPIGatewayClientGenerateTool = try context.tool(named: "APIGatewayClientGenerate")
        let sourcesDirectory = context.pluginWorkDirectory.appending("Sources")
        
        let inputFile = context.package.directory.appending("api-gateway-client-swift-codegen.json")
        let configFilePath = inputFile.string
        let configFile = FileHandle(forReadingAtPath: inputFile.string)
        
        guard let configData = configFile?.readDataToEndOfFile() else {
            throw PluginError.missingConfigFile(expectedPath: configFilePath)
        }
        
        let config = try JSONDecoder().decode(APIGatewayClientSwiftCodeGen.self, from: configData)
        
        let baseName = config.baseName
        
        let modelFilePathOverride = try getModelFilePathOverride(target: target, config: config,
                                                                 baseFilePath: context.package.directory)
        
        let clientDirectory = sourcesDirectory.appending(target.name)
        
        let clientConfigurationType = config.clientConfigurationType ?? .configurationObject
        let configurationOrGeneratorFileSuffix: String
        switch clientConfigurationType {
        case .configurationObject:
            configurationOrGeneratorFileSuffix = "Configuration"
        case .generator:
            configurationOrGeneratorFileSuffix = "Generator"
        }
        
        let clientFiles = ["APIGateway\(baseName)\(targetSuffix).swift",
                           "\(baseName)\(targetSuffix)Protocol.swift",
                           "\(baseName)Operations\(targetSuffix)Output.swift",
                           "APIGateway\(baseName)\(targetSuffix)\(configurationOrGeneratorFileSuffix).swift",
                           "\(baseName)InvocationsReporting.swift",
                           "\(baseName)OperationsReporting.swift",
                           "Mock\(baseName)\(targetSuffix).swift",
                           "\(baseName)Operations\(targetSuffix)Input.swift",
                           "Throwing\(baseName)\(targetSuffix).swift"]
        let clientOutputPaths = clientFiles.map { clientDirectory.appending($0) }
        
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = clientOutputPaths

        // Construct the command arguments.
        var commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenClient",
            "--model-path", modelFilePathOverride,
            "--client-target-name", target.name
        ]
        
        if let modelTargetName = getModelTargetName(target: target, config: config) {
            commandArgs.append(contentsOf: ["--model-target-name", modelTargetName])
        }

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating client files",
            executable: serviceModelSwiftAPIGatewayClientGenerateTool.path,
            arguments: commandArgs,
            inputFiles: inputFiles,
            outputFiles: outputFiles)
        
        return [command]
    }
    
    private func getModelTargetName(target: Target, config: APIGatewayClientSwiftCodeGen) -> String? {
        guard let modelTargets = config.modelTargets else {
            return nil
        }
        
        if let modelTargetName = modelTargets.targetMap[target.name]?.modelTargetName {
            return modelTargetName
        }
        
        if let modelTargetName = modelTargets.default?.modelTargetName {
            return modelTargetName
        }
        
        return nil
    }
    
    private func getModelFilePathOverride(target: Target, config: APIGatewayClientSwiftCodeGen,
                                          baseFilePath: PackagePlugin.Path) throws -> String {
        // find the model for the current target
        let targetModelLocationOptional = config.modelLocations?.targetMap[target.name]
        
        let modelLocation: ModelLocation
        if let theModelLocation = targetModelLocationOptional {
            modelLocation = theModelLocation
        } else if let theModelLocation = config.modelLocations?.default {
            modelLocation = theModelLocation
        } else {
            throw PluginError.missingModelLocation(target: target.name)
        }
                
        return try getModelFilePathOverride(target: target, modelLocation: modelLocation,
                                            baseFilePath: baseFilePath)
    }
    
    private func getModelFilePathOverride(target: Target, modelLocation: ModelLocation,
                                          baseFilePath: PackagePlugin.Path) throws -> String {
        // if the model is in a dependency
        if let modelProductDependency = modelLocation.modelProductDependency {
            let dependencies: [Product] = target.dependencies.compactMap { dependency in
                if case .product(let product) = dependency, product.name == modelProductDependency {
                    return product
                }
                
                return nil
            }
            
            // if there is no such dependency
            guard let modelProduct = dependencies.first else {
                throw PluginError.unknownModelPackageDependency(packageName: modelProductDependency)
            }
            
            let modelTargetDependency = modelLocation.modelTargetDependency ?? modelProductDependency
            
            let filteredTargets = modelProduct.targets.filter { $0.name == modelTargetDependency }
            guard let modelTarget = filteredTargets.first else {
                throw PluginError.unknownModelTargetDependency(packageName: modelProductDependency,
                                                               targetName: modelTargetDependency)
            }
            
            guard let modelTarget = modelTarget as? SourceModuleTarget else {
                throw PluginError.sourceModuleTargetRequired(packageName: modelProductDependency,
                                                             targetName: modelTargetDependency,
                                                             type: type(of: modelTarget))
            }
            
            let targetDirectory: String
            let rawTargetDirectory = modelTarget.directory.string
            if !rawTargetDirectory.hasSuffix("/") {
                targetDirectory = "\(rawTargetDirectory)/"
            } else {
                targetDirectory = rawTargetDirectory
            }
                  
            let filteredFiles = modelTarget.sourceFiles.filter { $0.path.string.dropFirst(targetDirectory.count) == modelLocation.modelFilePath }
            guard let modelFile = filteredFiles.first else {
                throw PluginError.unknownModelFilePath(packageName: modelProductDependency,
                                                       targetName: modelTargetDependency,
                                                       fileName: modelLocation.modelFilePath)
            }
            
            return modelFile.path.string
        }
        
        // the model is local to the package
        return baseFilePath.appending(modelLocation.modelFilePath).description
    }
}
