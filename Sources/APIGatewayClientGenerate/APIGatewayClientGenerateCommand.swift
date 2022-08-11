//
//  main.swift
//  APIGatewayClientGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import APIGatewayClientModelGenerate
import SwaggerServiceModel
import OpenAPIServiceModel
import ArgumentParser

private let configFileName = "api-gateway-client-swift-codegen.json"

enum APIGatewayClientGenerateCommandError: Error {
    case missingConfigFile(expectedPath: String)
    case invalidParameterConbination(reason: String)
}

@main
struct APIGatewayClientGenerateCommand: ParsableCommand {
    static var configuration: CommandConfiguration {
        return CommandConfiguration(
            commandName: "APIGatewayClientGenerate",
            abstract: "Code generator for clients contacting an AWS API Gateway hosted endpoint."
        )
    }
    
    @Option(name: .customLong("model-path"), help: "The file path for the model definition.")
    var modelFilePath: String?
    
    @Option(name: .customLong("base-file-path"), help: "The file path to the root of the input Swift package.")
    var baseFilePath: String
    
    @Option(name: .customLong("base-output-file-path"), help: "The file path to place the root of the generated Swift package.")
    var baseOutputFilePath: String?
    
    @Option(name: .customLong("generation-type"), help: "The code generation mode. Can only be specified with --model-path.")
    var generationType: GenerationType?
    
    @Option(name: .customLong("target"), help: "The name of the current target.")
    var target: String?

    mutating func run() throws {
        let configFilePath = "\(baseFilePath)/\(configFileName)"
        let configFile = FileHandle(forReadingAtPath: configFilePath)
        
        guard let configData = configFile?.readDataToEndOfFile() else {
            throw APIGatewayClientGenerateCommandError.missingConfigFile(expectedPath: configFilePath)
        }
        
        let config = try JSONDecoder().decode(APIGatewayClientSwiftCodeGen.self, from: configData)
        let baseName = config.baseName
        
        let httpClientConfiguration: HttpClientConfiguration
        if let httpClientConfigurationFromConfig = config.httpClientConfiguration {
            httpClientConfiguration = httpClientConfigurationFromConfig
        } else {
            httpClientConfiguration = HttpClientConfiguration(
                retryOnUnknownError: true,
                knownErrorsDefaultRetryBehavior: .fail,
                unretriableUnknownErrors: [],
                retriableUnknownErrors: [])
        }
        
        let validationErrorDeclaration = ErrorDeclaration.internal
        let unrecognizedErrorDeclaration = ErrorDeclaration.internal
        let customizations = CodeGenerationCustomizations(
            validationErrorDeclaration: validationErrorDeclaration,
            unrecognizedErrorDeclaration: unrecognizedErrorDeclaration,
            asyncAwaitAPIs: .enabled,
            eventLoopFutureClientAPIs: config.eventLoopFutureClientAPIs ?? .disabled,
            minimumCompilerSupport: config.minimumCompilerSupport ?? .v5_6,
            clientConfigurationType: config.clientConfigurationType ?? .configurationObject,
            generateModelShapeConversions: config.shapeProtocols?.boolean ?? false,
            optionalsInitializeEmpty: false,
            fileHeader: nil,
            httpClientConfiguration: httpClientConfiguration)
                        
        let fullApplicationDescription = ApplicationDescription(baseName: baseName,
                                                                baseFilePath: baseOutputFilePath ?? baseFilePath,
                                                                applicationDescription: "The \(baseName) Swift client.",
                                                                applicationSuffix: "")
        
        if let modelFilePath = modelFilePath, let generationType = generationType {
            let modelFormat = config.modelFormat ?? .openAPI30
            
            switch modelFormat {
            case .openAPI30:
                _ = try APIGatewayClientCodeGeneration.generateFromModel(
                    modelFilePath: modelFilePath,
                    modelType: OpenAPIServiceModel.self,
                    generationType: generationType,
                    modelLocation: getModelLocation(config: config),
                    customizations: customizations,
                    applicationDescription: fullApplicationDescription,
                    modelOverride: config.modelOverride)
            case .swagger:
                _ = try APIGatewayClientCodeGeneration.generateFromModel(
                    modelFilePath: modelFilePath,
                    modelType: SwaggerServiceModel.self,
                    generationType: generationType,
                    modelLocation: getModelLocation(config: config),
                    customizations: customizations,
                    applicationDescription: fullApplicationDescription,
                    modelOverride: config.modelOverride)
            }
        } else if modelFilePath == nil {
            APIGatewayClientCodeGeneration.generateWithNoModel(
                modelLocation: getModelLocation(config: config),
                customizations: customizations,
                applicationDescription: fullApplicationDescription,
                modelOverride: config.modelOverride)
        } else {
            throw APIGatewayClientGenerateCommandError.invalidParameterConbination(
                reason: "--generation-type and --model-type must be both specified (from a plugin) or neither (from the command line).")
        }
    }
    
    private func getModelLocation(config: APIGatewayClientSwiftCodeGen) -> ModelLocation? {
        // find the model for the current target
        let filteredModelLocations = config.modelLocations?.targetMap.compactMap { (targetName, modelLocation) -> ModelLocation? in
            if targetName == target {
                return modelLocation
            }
            
            return nil
        }
        
        let modelLocation: ModelLocation
        if let theModelLocation = filteredModelLocations?.first {
            modelLocation = theModelLocation
        } else if let theModelLocation = config.modelLocations?.default {
            modelLocation = theModelLocation
        } else {
            return nil
        }
        
        return modelLocation
    }
}

extension CodeGenFeatureStatus {
    var boolean: Bool {
        switch self {
        case .disabled:
            return false
        case .enabled:
            return true
        }
    }
}

