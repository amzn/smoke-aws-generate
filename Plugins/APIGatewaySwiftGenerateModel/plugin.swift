import PackagePlugin
import Foundation

private let targetSuffix = "Model"

enum PluginError: Error {
    case unknownModelPackageDependency(packageName: String)
    case unknownModelTargetDependency(packageName: String, targetName: String)
    case sourceModuleTargetRequired(packageName: String, targetName: String, type: Target.Type)
    case unknownModelFilePath(packageName: String, targetName: String, fileName: String)
    case missingConfigFile(expectedPath: String)
    case missingModelLocation(target: String)
}

@main
struct APIGatewaySwiftGenerateModelPlugin: BuildToolPlugin {
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
    
    struct APIGatewayClientSwiftCodeGen: Decodable {
        let baseName: String
        let modelLocations: ModelLocations?
    }
    
    /// This plugin's implementation returns a single build command which
    /// calls `APIGatewayClientGenerate` to generate the service model.
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
        
        let modelDirectory = sourcesDirectory.appending(target.name)
        
        let modelFiles = ["\(baseName)\(targetSuffix)Errors.swift",
                          "\(baseName)\(targetSuffix)Structures.swift",
                          "\(baseName)\(targetSuffix)DefaultInstances.swift",
                          "\(baseName)\(targetSuffix)Operations.swift",
                          "\(baseName)\(targetSuffix)Types.swift"]
        let modelOutputPaths = modelFiles.map { modelDirectory.appending($0) }
                
        // Specifying the input and output paths lets the build system know
        // when to invoke the command.
        let inputFiles = [inputFile]
        let outputFiles = modelOutputPaths

        // Construct the command arguments.
        let commandArgs = [
            "--base-file-path", context.package.directory.description,
            "--base-output-file-path", context.pluginWorkDirectory.description,
            "--generation-type", "codeGenModel",
            "--model-path", modelFilePathOverride,
            "--model-target-name", target.name
        ]

        // Append a command containing the information we generated.
        let command: Command = .buildCommand(
            displayName: "Generating model files",
            executable: serviceModelSwiftAPIGatewayClientGenerateTool.path,
            arguments: commandArgs,
            inputFiles: inputFiles,
            outputFiles: outputFiles)
        
        return [command]
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
