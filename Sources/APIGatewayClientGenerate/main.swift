// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// main.swift
// APIGatewayClientGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import APIGatewayClientModelGenerate
import SwaggerServiceModel

var isUsage = CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "--help"

struct Options {
    static let modelFilePathOption = "--model-path"
    static let baseNameOption = "--base-name"
    static let baseFilePathOption = "--base-file-path"
    static let modelOverridePathOption = "--model-override-path"
    static let httpClientConfigurationPathOption = "--http-client-configuration-path"
}

func printUsage() {
    let usage = """
        OVERVIEW: Generate a swift client package based on a Swagger Model.

        USAGE: ServiceModelSwiftAPIGatewayClientGenerate [options]

        OPTIONS:
          --model-path         The file path for the model definition.
          --base-name          The base name for the generated libraries and executable.
                               The generate executable will have the name-
                                 <base-name>Client.
                               Libraries for the application will have names-
                                 <base-name><generator-defined-library-type-name>
          --base-file-path     The file path to place the root of the generated Swift package.
          [--model-override-path]
                               The file path to model override parameters.
          [--http-client-configuration-path]
                               The file path to the configuration for the http client.
                               If not specified, the http client will consider all
                               known errors as unretriable and all unknown errors as
                               unretriable.
        """
    
    print(usage)
}

private func getOptions(
        missingOptions: inout Set<String>,
        modelFilePath: inout String?,
        baseName: inout String?,
        baseFilePath: inout String?,
        modelOverridePath: inout String?,
        httpClientConfigurationPath: inout String?,
        errorMessage: inout String?) {
    var currentOption: String?
    for argument in CommandLine.arguments.dropFirst() {
        if currentOption == nil && argument.hasPrefix("--") {
            currentOption = argument
            missingOptions.remove(argument)
        } else if let option = currentOption, !argument.hasPrefix("--") {
            switch option {
            case Options.modelFilePathOption:
                modelFilePath = argument
            case Options.baseNameOption:
                baseName = argument
            case Options.baseFilePathOption:
                baseFilePath = argument
            case Options.modelOverridePathOption:
                modelOverridePath = argument
            case Options.httpClientConfigurationPathOption:
                httpClientConfigurationPath = argument
            default:
                errorMessage = "Unrecognized option: \(option)"
            }
            
            currentOption = nil
        } else {
            printUsage()
            
            break
        }
        
    }
}

func getModelOverride(modelOverridePath: String?) throws -> ModelOverride? {
    let modelOverride: ModelOverride?
    if let modelOverridePath = modelOverridePath {
        let overrideFile = FileHandle(forReadingAtPath: modelOverridePath)
    
        guard let overrideData = overrideFile?.readDataToEndOfFile() else {
            fatalError("Specified model file '\(modelOverridePath) doesn't exist.'")
        }
        
        modelOverride = try JSONDecoder().decode(ModelOverride.self, from: overrideData)
    } else {
        modelOverride = nil
    }
    
    return modelOverride
}

func getHttpClientConfiguration(
        httpClientConfigurationPath: String?) throws -> HttpClientConfiguration {
    let httpClientConfiguration: HttpClientConfiguration
    if let httpClientConfigurationPath = httpClientConfigurationPath {
        let overrideFile = FileHandle(forReadingAtPath: httpClientConfigurationPath)
    
        guard let overrideData = overrideFile?.readDataToEndOfFile() else {
            fatalError("Specified model file '\(httpClientConfigurationPath) doesn't exist.'")
        }
        
        httpClientConfiguration = try JSONDecoder().decode(HttpClientConfiguration.self,
                                                           from: overrideData)
    } else {
        httpClientConfiguration = HttpClientConfiguration(
            retryOnUnknownError: true,
            knownErrorsDefaultRetryBehavior: .fail,
            unretriableUnknownErrors: [],
            retriableUnknownErrors: [])
    }
    
    return httpClientConfiguration
}

func handleApplication() throws {
    var errorMessage: String?
    
    var modelFilePath: String?
    var baseName: String?
    var baseFilePath: String?
    var modelOverridePath: String?
    var httpClientConfigurationPath: String?
    var missingOptions: Set<String> = [Options.modelFilePathOption,
                                       Options.baseNameOption,
                                       Options.baseFilePathOption]
    
    getOptions(missingOptions: &missingOptions, modelFilePath: &modelFilePath,
               baseName: &baseName, baseFilePath: &baseFilePath,
               modelOverridePath: &modelOverridePath,
               httpClientConfigurationPath: &httpClientConfigurationPath,
               errorMessage: &errorMessage)
    
    let modelOverride = try getModelOverride(modelOverridePath: modelOverridePath)
    let httpClientConfiguration = try getHttpClientConfiguration(
        httpClientConfigurationPath: httpClientConfigurationPath)
    
    if errorMessage == nil {
        if let modelFilePath = modelFilePath,
            let baseName = baseName,
            let baseFilePath = baseFilePath {
            
            let validationErrorDeclaration = ErrorDeclaration.internal
            let unrecognizedErrorDeclaration = ErrorDeclaration.internal
            let customizations = CodeGenerationCustomizations(
                validationErrorDeclaration: validationErrorDeclaration,
                unrecognizedErrorDeclaration: unrecognizedErrorDeclaration,
                generateModelShapeConversions: false,
                optionalsInitializeEmpty: true,
                fileHeader: nil,
                httpClientConfiguration: httpClientConfiguration)
            
            let fullApplicationDescription = ApplicationDescription(
                baseName: baseName,
                baseFilePath: baseFilePath,
                applicationDescription: "The \(baseName) Swift client.",
                applicationSuffix: "Client")
            
            try APIGatewayClientCodeGeneration.generateFromModel(
                modelFilePath: modelFilePath,
                modelType: SwaggerServiceModel.self,
                customizations: customizations,
                applicationDescription: fullApplicationDescription,
                modelOverride: modelOverride)
        } else {
            var missingOptionsString: String = ""
            missingOptions.forEach { option in missingOptionsString += " " + option }
            
            errorMessage = "Missing required options:" + missingOptionsString
        }
    }
    
    if let errorMessage = errorMessage {
        print("ERROR: \(errorMessage)\n")
        
        printUsage()
    }
}

if isUsage {
    printUsage()
} else {
    try handleApplication()
}
