//
//  APIGatewayClientInitializeCommandError.swift
//  APIGatewayClientInitialize
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import APIGatewayClientModelGenerate
import SwaggerServiceModel
import OpenAPIServiceModel
import ArgumentParser

private let configFileName = "api-gateway-client-swift-codegen.json"

enum APIGatewayClientInitializeCommandError: Error {
    case missingConfigFile(expectedPath: String)
    case invalidParameterConbination(reason: String)
}

@main
struct APIGatewayClientInitializeCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "APIGatewayClientInitialize",
            abstract: "Code generator for initializing a Swift Package for clients contacting an AWS API Gateway hosted endpoint."
        )
    }
    
    @Option(name: .customLong("base-file-path"), help: "The file path to the root of the input Swift package.")
    var baseFilePath: String
    
    @Option(name: .customLong("base-name"), help: """
        The base name for the generated libraries and executable.
        The generate executable will have the name-
          <base-name><application-suffix>.
        Libraries for the application will have names-
          <base-name><generator-defined-library-type-name>
        """)
    var baseName: String
    
    @Option(name: .customLong("model-format"), help: "The format of the model file being used.")
    var modelFormat: ModelFormat
    
    @Option(name: .customLong("model-path"), help: "The file path for the model definition.")
    var modelFilePath: String
    
    @Option(name: .customLong("model-product-dependency"),
            help: "For models hosted in an external product, the name of that product.")
    var modelProductDependency: String?
    
    @Option(name: .customLong("model-target-dependency"), help: """
        For models hosted in an external product, the name of that product's target.
        If not specified, the name of the product is also used for target name.
        """)
    var modelTargetDependency: String?
    
    @Option(name: .customLong("package-location"),
            help: "For models hosted in an external product, the path of the dependency package.")
    var packageLocation: String?
    
    @Option(name: .customLong("version-requirement"),
            help: "For models hosted in an external product, the version requirement of the package dependency.")
    var versionRequirement: String?
    
    @Option(name: .customLong("version-requirement-type"),
            help: "For models hosted in an external product, the version requirement type of the package dependency.")
    var versionRequirementType: VersionRequirementType?
    
    @Option(name: .customLong("model-target-name"), help: """
            When GenerationType == .codeGenModel, the name of this target;
            When GenerationType == .codeGenClient, the name of the target with the generated model types.
            """)
    var modelTargetName: String?
    
    @Option(name: .customLong("client-target-name"), help: """
            When GenerationType == .codeGenModel, ignored;
            When GenerationType == .codeGenClient, the name of this target.
            """)
    var clientTargetName: String?

    mutating func run() throws {
        let fullApplicationDescription = ApplicationDescription(baseName: baseName,
                                                                baseFilePath: baseFilePath,
                                                                applicationDescription: "The \(baseName) Swift client.",
                                                                applicationSuffix: "")
        
        let modelPackageDependency: ModelPackageDependency?
        if self.modelProductDependency != nil {
            guard let packageLocation = self.packageLocation, let versionRequirementType = self.versionRequirementType else {
                fatalError("package-location and version-requirement-type must be specified if model-product-dependency is")
            }
            
            modelPackageDependency = ModelPackageDependency(versionRequirementType: versionRequirementType,
                                                            versionRequirement: self.versionRequirement,
                                                            packageLocation: packageLocation)
        } else {
            modelPackageDependency = nil
        }
        
        let modelLocation = ModelLocation(modelFilePath: self.modelFilePath,
                                          modelProductDependency: self.modelProductDependency,
                                          modelTargetDependency: self.modelTargetDependency)
        
        let modelTargetName = self.modelTargetName ?? "\(baseName)Model"
        let clientTargetName = self.clientTargetName ?? "\(baseName)Client"
        
        APIGatewayClientCodeGeneration.generateWithNoModel(
            modelLocation: modelLocation,
            modelTargetName: modelTargetName, clientTargetName: clientTargetName,
            modelPackageDependency: modelPackageDependency,
            applicationDescription: fullApplicationDescription,
            fileHeader: nil)
        
        let configFilePath = "\(baseFilePath)/\(configFileName)"
        
        let modelTargets: ModelTargets?
        if let modelTargetName = self.modelTargetName {
            let modelTarget = ModelTarget(modelTargetName: modelTargetName)
            
            modelTargets = ModelTargets(default: nil,
                                        targetMap: [clientTargetName : modelTarget])
        } else {
            modelTargets = nil
        }
        
        if !FileManager.default.fileExists(atPath: configFilePath) {
            let apiGatewayClientSwiftCodeGen = APIGatewayClientSwiftCodeGen(
                modelFormat: self.modelFormat,
                modelLocations: ModelLocations(default: modelLocation),
                modelTargets: modelTargets,
                baseName: self.baseName)
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let data = try jsonEncoder.encode(apiGatewayClientSwiftCodeGen)
            
            try data.write(to: URL.init(fileURLWithPath: configFilePath))
        }
    }
}

